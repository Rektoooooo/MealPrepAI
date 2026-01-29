/**
 * Substitute Ingredient API Endpoint
 *
 * POST /api/v1/substitute-ingredient
 *
 * Generates 3 AI-powered ingredient substitutes using Claude AI with:
 * - Dietary restriction & allergy awareness
 * - Accurate per-100g nutrition data
 * - Pre-calculated totals for suggested quantities
 * - Rate limiting per device
 */

import Anthropic from '@anthropic-ai/sdk';
import { checkRateLimit } from '../utils/rateLimiter';

// Types
interface SubstituteIngredientRequest {
  ingredientName: string;
  ingredientQuantity: number;
  ingredientUnit: string;
  recipeContext: {
    recipeName: string;
    totalCalories: number;
    totalProtein: number;
    totalCarbs: number;
    totalFat: number;
    otherIngredients: string[];
  };
  dietaryRestrictions: string[];
  allergies: string[];
  deviceId: string;
}

interface SubstituteOption {
  name: string;
  reason: string;
  quantity: number;
  unit: string;
  quantityGrams: number;
  category: string;
  caloriesPer100g: number;
  proteinPer100g: number;
  carbsPer100g: number;
  fatPer100g: number;
  totalCalories: number;
  totalProtein: number;
  totalCarbs: number;
  totalFat: number;
}

interface SubstituteIngredientResponse {
  success: boolean;
  substitutes?: SubstituteOption[];
  error?: string;
  rateLimitInfo?: {
    remaining: number;
    resetTime: string;
    limit: number;
  };
}

// Claude client - initialized lazily
let anthropic: Anthropic | null = null;

function getAnthropicClient(): Anthropic {
  if (!anthropic) {
    const apiKey = process.env.ANTHROPIC_API_KEY;
    if (!apiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set');
    }
    anthropic = new Anthropic({ apiKey });
  }
  return anthropic;
}

/**
 * Parse Claude's JSON response for substitutes
 */
function parseSubstitutesResponse(content: string): SubstituteOption[] {
  let cleanJSON = content
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .trim();

  const startIndex = cleanJSON.indexOf('{');
  const endIndex = cleanJSON.lastIndexOf('}');

  if (startIndex === -1 || endIndex === -1) {
    throw new Error('No valid JSON object found in response');
  }

  cleanJSON = cleanJSON.substring(startIndex, endIndex + 1);

  try {
    const parsed = JSON.parse(cleanJSON) as { substitutes: SubstituteOption[] };
    if (!parsed.substitutes || !Array.isArray(parsed.substitutes)) {
      throw new Error('Response missing substitutes array');
    }
    return parsed.substitutes;
  } catch {
    throw new Error('Failed to parse JSON response from Claude');
  }
}

/**
 * Main handler for substitute-ingredient endpoint
 */
export async function handleSubstituteIngredient(
  req: SubstituteIngredientRequest
): Promise<SubstituteIngredientResponse> {
  const {
    ingredientName,
    ingredientQuantity,
    ingredientUnit,
    recipeContext,
    dietaryRestrictions,
    allergies,
    deviceId,
  } = req;

  console.log('[DEBUG] ========== SUBSTITUTE INGREDIENT START ==========');
  console.log('[DEBUG] Device ID:', deviceId);
  console.log('[DEBUG] Ingredient:', ingredientName, ingredientQuantity, ingredientUnit);
  console.log('[DEBUG] Recipe:', recipeContext?.recipeName);

  // Validate required fields
  if (!deviceId) {
    return { success: false, error: 'Device ID is required' };
  }
  if (!ingredientName) {
    return { success: false, error: 'Ingredient name is required' };
  }
  if (!recipeContext) {
    return { success: false, error: 'Recipe context is required' };
  }

  // Check rate limit
  const rateLimit = await checkRateLimit(deviceId, 'substitute-ingredient');
  if (!rateLimit.allowed) {
    return {
      success: false,
      error: 'Rate limit exceeded. Please try again later.',
      rateLimitInfo: {
        remaining: rateLimit.remaining,
        resetTime: rateLimit.resetTime.toISOString(),
        limit: rateLimit.limit,
      },
    };
  }

  try {
    const client = getAnthropicClient();

    const systemPrompt = `You are a professional nutritionist. Given an ingredient in a recipe, suggest exactly 3 substitutes.
Respond ONLY with valid JSON. No markdown.
Each substitute must work culinarily in the recipe, respect dietary restrictions and allergies strictly,
and include accurate per-100g nutrition plus pre-calculated totals for the suggested quantity.`;

    const restrictions = dietaryRestrictions?.join(', ') || 'None';
    const allergyList = allergies?.join(', ') || 'None';
    const otherIngredients = recipeContext.otherIngredients?.join(', ') || 'None';

    const userPrompt = `Replace "${ingredientName}" (${ingredientQuantity} ${ingredientUnit}) in "${recipeContext.recipeName}".
Other ingredients: ${otherIngredients}
Recipe macros: ${recipeContext.totalCalories} cal, ${recipeContext.totalProtein}g P, ${recipeContext.totalCarbs}g C, ${recipeContext.totalFat}g F
DIETARY RESTRICTIONS: ${restrictions}
ALLERGIES (NEVER include these): ${allergyList}

Respond with: { "substitutes": [ { "name": "string", "reason": "max 10 words", "quantity": number, "unit": "string", "quantityGrams": number, "category": "produce|meat|dairy|pantry|frozen|bakery|beverages|other", "caloriesPer100g": number, "proteinPer100g": number, "carbsPer100g": number, "fatPer100g": number, "totalCalories": number, "totalProtein": number, "totalCarbs": number, "totalFat": number } ] }`;

    console.log('[DEBUG] Calling Claude API for ingredient substitution...');
    const startTime = Date.now();

    const response = await client.messages.create({
      model: 'claude-3-5-haiku-latest',
      max_tokens: 1500,
      system: systemPrompt,
      messages: [{ role: 'user', content: userPrompt }],
    });

    const apiDuration = Date.now() - startTime;
    console.log('[DEBUG] Claude API response received in', apiDuration, 'ms');

    const textContent = response.content.find((c: Anthropic.ContentBlock) => c.type === 'text');
    if (!textContent || textContent.type !== 'text') {
      throw new Error('No text content in Claude response');
    }

    const substitutes = parseSubstitutesResponse(textContent.text);
    console.log('[DEBUG] Parsed', substitutes.length, 'substitutes');

    return {
      success: true,
      substitutes,
      rateLimitInfo: {
        remaining: rateLimit.remaining,
        resetTime: rateLimit.resetTime.toISOString(),
        limit: rateLimit.limit,
      },
    };
  } catch (error) {
    console.error('[DEBUG] Substitute ingredient error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';
    return {
      success: false,
      error: `Failed to generate substitutes: ${errorMessage}`,
    };
  }
}
