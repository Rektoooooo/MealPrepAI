# Custom Recipe Database

## Current Status

✅ **12 recipes collected with complete nutrition data**
- 4 Breakfast recipes
- 7 Dinner/Lunch recipes
- 1 Snack recipe

All recipes include:
- Complete nutrition (calories, protein, carbs, fat)
- Detailed ingredients with measurements
- Step-by-step instructions
- High-quality images
- Health scores and diet tags

## Directory Structure

```
firebase/scripts/
├── recipes/
│   ├── breakfast.json    # 4 breakfast recipes
│   ├── dinner.json       # 7 lunch/dinner recipes
│   ├── snacks.json       # 1 snack recipe
│   └── lunch.json        # (empty - lunch recipes in dinner.json)
└── uploadRecipes.js      # Firebase upload script
```

## Uploading to Firebase

### Prerequisites

1. Install Firebase Admin SDK:
   ```bash
   cd firebase/scripts
   npm install firebase-admin
   ```

2. Set up authentication (choose one):
   - **Option A**: Set environment variable
     ```bash
     export GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
     ```
   - **Option B**: Edit `uploadRecipes.js` and uncomment the credential line

### Upload Command

```bash
cd firebase/scripts
node uploadRecipes.js
```

This will upload all recipes to the `custom_recipes` Firestore collection.

## Challenges Encountered

### 1. **Web Scraping Limitations**
- Many recipe sites block automated scraping (403 errors)
- Sites like Budget Bytes, Eating Bird Food blocked our requests
- Skinnytaste worked well but is slow (one recipe at a time)

### 2. **Free Recipe APIs Lack Nutrition Data**
- **TheMealDB**: Free but NO nutrition information (no calories, protein, carbs, fat)
- **Recipe Puppy**: Basic recipe search, no nutrition data
- **Edamam**: Has nutrition but requires paid plan for bulk access

### 3. **Scale vs Speed**
- Original goal: 200-500 recipes
- Current collection rate: ~3-5 recipes per hour with web scraping
- Estimated time to reach 200 recipes: 40-70 hours of work

## Recommended Path Forward

### Option 1: Continue with Skinnytaste (Slow but High Quality)
**Pros:**
- Excellent nutrition data
- Verified, tested recipes
- Healthy, weight-loss focused

**Cons:**
- Very slow (40+ hours for 200 recipes)
- Limited to one source

**Time**: 40-70 hours

### Option 2: Use TheMealDB + Calculate Nutrition (Faster)
**Pros:**
- Fast recipe collection (1000+ recipes available)
- Free API access
- Good variety of cuisines

**Cons:**
- NO built-in nutrition data
- Must calculate nutrition using USDA FoodData Central API
- Nutrition calculations may be estimates

**Time**: 10-20 hours (with nutrition calculations)

### Option 3: Create Curated Collection (Balanced Approach) ⭐ **RECOMMENDED**
**Target:** 50-100 high-quality recipes instead of 200-500

**Strategy:**
- Focus on variety: 15 breakfast, 25 lunch, 25 dinner, 15 snacks
- Mix sources: Skinnytaste (nutrition verified) + TheMealDB (calculated nutrition)
- Prioritize most popular/useful recipes

**Pros:**
- Achievable in reasonable time (15-25 hours)
- High quality, curated selection
- Can expand later as needed

**Cons:**
- Smaller initial database

**Time**: 15-25 hours

### Option 4: Use Existing Spoonacular Integration
**The app already integrates with Spoonacular which has:**
- 5000+ recipes with full nutrition
- Already working in the codebase
- Filtered by dietary preferences

**Why add custom recipes?**
- Spoonacular may have API limits/costs
- Custom recipes give you full control
- Can add recipes specifically tailored to your users

## Next Steps

### If continuing with Option 3 (Recommended):

1. **Continue collecting from Skinnytaste** (10-15 hours)
   - Focus on most popular recipes
   - Aim for ~40 more recipes

2. **Add TheMealDB recipes** (5-10 hours)
   - Select 20-30 recipes
   - Calculate nutrition using USDA API

3. **Upload to Firebase**
   ```bash
   node uploadRecipes.js
   ```

4. **Update iOS app** to query `custom_recipes` collection

### Alternative: Start Using What We Have

The 12 recipes we have are high-quality and ready to use:
- Upload now with `node uploadRecipes.js`
- Start showing them in the app
- Expand database gradually over time

## Recipe Quality Checklist

All current recipes meet these criteria:
- ✅ Complete nutrition facts
- ✅ Calories: 100-600 per serving
- ✅ Protein: 2-50g per serving
- ✅ Clear instructions (3+ steps)
- ✅ Ingredient list with measurements
- ✅ High-quality images
- ✅ Source attribution

## Data Schema

Each recipe follows this Firebase schema:

```json
{
  "externalId": 10001,
  "title": "Recipe Name",
  "imageUrl": "https://...",
  "readyInMinutes": 30,
  "servings": 4,
  "calories": 350,
  "proteinGrams": 30,
  "carbsGrams": 25,
  "fatGrams": 12,
  "instructions": ["Step 1", "Step 2", ...],
  "cuisineType": "mediterranean",
  "mealType": "lunch",
  "diets": ["high-protein", "low-carb"],
  "dishTypes": ["main course"],
  "healthScore": 85,
  "sourceUrl": "https://...",
  "creditsText": "Recipe from SourceName",
  "ingredients": [
    {"name": "Chicken", "amount": 200, "unit": "g", "aisle": "Meat"}
  ],
  "createdAt": "2026-01-26T00:00:00Z"
}
```

## Sources Used

All recipes properly attributed:
- **Skinnytaste** (11 recipes) - Health-focused, verified nutrition
- **Minimalist Baker** (1 recipe) - Plant-based options

### Web Search Sources Referenced
- [Skinnytaste High Protein Snacks](https://www.skinnytaste.com/high-protein-snacks/)
- [The Real Food Dietitians Breakfast Ideas](https://therealfooddietitians.com/high-protein-breakfast-ideas/)
- [Clean Eatz Kitchen High Protein Meals](https://www.cleaneatzkitchen.com/a/blog/15-high-protein-meals-under-500-calories)
- [Hurry The Food Up Low Calorie Lunches](https://hurrythefoodup.com/low-calorie-lunches/)
- [Healthline High Protein Snacks](https://www.healthline.com/nutrition/healthy-high-protein-snacks)
- [Eating Bird Food Protein Recipes](https://www.eatingbirdfood.com/high-protein-breakfast-recipes/)
- [Minimalist Baker Protein Recipes](https://minimalistbaker.com/20-high-protein-high-fiber-dinners/)
