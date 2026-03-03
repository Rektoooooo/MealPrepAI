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
import { checkRateLimit, incrementRateLimit } from '../utils/rateLimiter';

const DEBUG = process.env.FUNCTIONS_EMULATOR === 'true';

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
    anthropic = new Anthropic({ apiKey, timeout: 60000 });
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

  if (DEBUG) {
    console.log('[DEBUG] ========== SUBSTITUTE INGREDIENT START ==========');
    console.log('[DEBUG] Device ID:', deviceId);
    console.log('[DEBUG] Ingredient:', ingredientName, ingredientQuantity, ingredientUnit);
    console.log('[DEBUG] Recipe:', recipeContext?.recipeName);
  }

  // Validate required fields
  if (!deviceId || typeof deviceId !== 'string' || deviceId.length > 128 || !/^[\w-]+$/.test(deviceId)) {
    return { success: false, error: 'Invalid device ID' };
  }
  if (!ingredientName || typeof ingredientName !== 'string' || ingredientName.length > 200) {
    return { success: false, error: 'Invalid ingredient name' };
  }
  if (typeof ingredientQuantity !== 'number' || ingredientQuantity <= 0 || ingredientQuantity > 100000) {
    return { success: false, error: 'Invalid ingredient quantity' };
  }
  if (!ingredientUnit || typeof ingredientUnit !== 'string') {
    return { success: false, error: 'Invalid ingredient unit' };
  }
  if (!recipeContext || typeof recipeContext !== 'object') {
    return { success: false, error: 'Recipe context is required' };
  }
  if (!recipeContext.recipeName || typeof recipeContext.recipeName !== 'string') {
    return { success: false, error: 'Recipe name is required' };
  }
  if (!Array.isArray(dietaryRestrictions)) {
    return { success: false, error: 'Invalid dietary restrictions' };
  }
  if (!Array.isArray(allergies)) {
    return { success: false, error: 'Invalid allergies' };
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

    if (DEBUG) console.log('[DEBUG] Calling Claude API for ingredient substitution...');
    const startTime = Date.now();

    const response = await client.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 1500,
      system: systemPrompt,
      messages: [{ role: 'user', content: userPrompt }],
    });

    const apiDuration = Date.now() - startTime;
    if (DEBUG) console.log('[DEBUG] Claude API response received in', apiDuration, 'ms');

    const textContent = response.content.find((c: Anthropic.ContentBlock) => c.type === 'text');
    if (!textContent || textContent.type !== 'text') {
      throw new Error('No text content in Claude response');
    }

    const substitutes = parseSubstitutesResponse(textContent.text);
    if (DEBUG) console.log('[DEBUG] Parsed', substitutes.length, 'substitutes');

    // Only count against rate limit after successful substitution
    const updatedLimit = await incrementRateLimit(deviceId, 'substitute-ingredient');

    return {
      success: true,
      substitutes,
      rateLimitInfo: {
        remaining: updatedLimit.remaining,
        resetTime: updatedLimit.resetTime.toISOString(),
        limit: updatedLimit.limit,
      },
    };
  } catch (error) {
    if (DEBUG) console.error('[DEBUG] Substitute ingredient error:', error);
    return {
      success: false,
      error: 'Failed to generate substitutes. Please try again.',
    };
  }
}
