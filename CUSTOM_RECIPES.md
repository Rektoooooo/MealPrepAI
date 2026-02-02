# Custom Recipe Integration Guide

## Overview

Your app now combines recipes from **two sources**:
1. **Spoonacular API** - Large database of recipes (existing integration)
2. **Custom Curated Recipes** - Hand-picked, high-quality recipes with verified nutrition data

## What's Been Implemented

### 1. Recipe Collection ✅
- **12 high-quality recipes** collected with complete nutrition data
- 4 Breakfast recipes (egg muffins, protein pancakes)
- 7 Lunch/Dinner recipes (chicken, salmon, shrimp, turkey)
- 1 Snack recipe (protein bars)
- All recipes include calories, protein, carbs, fat, fiber
- High-quality images from Skinnytaste and Minimalist Baker

### 2. Firebase Upload Script ✅
- Located at `firebase/scripts/uploadRecipes.js`
- Uploads recipes to `custom_recipes` Firestore collection
- Handles batching (500 recipes at a time)
- Includes error handling and progress logging

### 3. iOS App Integration ✅
- `FirebaseRecipeService` updated to query both collections
- Custom recipes are marked with `isCustomRecipe = true`
- Results are merged and deduplicated
- Pagination works across both collections

## Directory Structure

```
firebase/scripts/
├── recipes/
│   ├── breakfast.json    # 4 breakfast recipes
│   ├── dinner.json       # 7 lunch/dinner recipes
│   └── snacks.json       # 1 snack recipe
├── uploadRecipes.js      # Upload script
└── README.md             # Detailed documentation
```

---

## How to Upload Recipes to Firebase

### Step 1: Install Dependencies

```bash
cd firebase/scripts
npm install firebase-admin
```

### Step 2: Set Up Firebase Authentication

You need Firebase Admin SDK credentials. Choose one option:

#### Option A: Environment Variable (Recommended)
```bash
# Download your service account key from Firebase Console
# Firebase Console → Project Settings → Service Accounts → Generate new private key

export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
```

#### Option B: Edit Script Directly
```javascript
// In uploadRecipes.js, uncomment and update:
admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json'))
});
```

### Step 3: Upload Recipes

```bash
cd firebase/scripts
node uploadRecipes.js
```

Expected output:
```
Loaded 4 recipes from breakfast.json
Loaded 7 recipes from dinner.json
Loaded 1 recipes from snacks.json

📤 Uploading 12 recipes to Firestore...

✅ Uploaded 12/12 recipes

🎉 Successfully uploaded all 12 recipes!

Recipes are now available in the 'custom_recipes' collection

✨ Upload complete!
```

---

## How the iOS App Works

### Fetching Recipes

The `FirebaseRecipeService` now automatically queries **both** collections:

```swift
// Fetches from both 'recipes' and 'custom_recipes'
let recipes = try await firebaseRecipeService.fetchRecipes(limit: 100)

// Custom recipes are marked:
recipes.filter { $0.isCustomRecipe } // Only custom curated recipes
recipes.filter { !$0.isCustomRecipe } // Only Spoonacular recipes
```

### Recipe Display

Custom recipes can be identified and displayed with a badge:

```swift
ForEach(recipes) { recipe in
    HStack {
        Text(recipe.title)
        if recipe.isCustomRecipe {
            Badge("Curated")
                .foregroundColor(.brandGreen)
        }
    }
}
```

### Search & Filtering

All existing filtering works across both sources:
- Search by title
- Filter by cuisine
- Filter by meal type
- Filter by dietary restrictions
- Sort by nutrition

---

## Recipe Schema

Each custom recipe follows this format:

```json
{
  "externalId": 10001,
  "title": "Egg White Muffins with Turkey Bacon",
  "imageUrl": "https://www.skinnytaste.com/.../image.jpg",
  "readyInMinutes": 50,
  "servings": 6,
  "calories": 144,
  "proteinGrams": 20,
  "carbsGrams": 4.5,
  "fatGrams": 4.5,
  "instructions": [
    "Preheat oven to 350°F...",
    "Sauté vegetables...",
    "Combine ingredients..."
  ],
  "cuisineType": "american",
  "mealType": "breakfast",
  "diets": ["high-protein", "low-carb"],
  "dishTypes": ["breakfast"],
  "healthScore": 92,
  "sourceUrl": "https://www.skinnytaste.com/...",
  "creditsText": "Recipe from Skinnytaste",
  "ingredients": [
    {
      "name": "Egg Whites",
      "amount": 16,
      "unit": "oz",
      "aisle": "Dairy"
    }
  ],
  "createdAt": "2026-01-26T00:00:00Z"
}
```

---

## Testing the Integration

### 1. Upload Recipes to Firebase

```bash
cd firebase/scripts
node uploadRecipes.js
```

### 2. Verify in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **MealPrepAI**
3. Navigate to **Firestore Database**
4. You should see a `custom_recipes` collection with 12 documents

### 3. Test in iOS App

1. Open the app in Xcode
2. Navigate to the **Recipes** tab
3. You should see recipes from both Spoonacular and your custom collection
4. Custom recipes will have higher quality images and verified nutrition

---

## Adding More Recipes

### Option 1: Manual Addition

1. Create a new JSON file in `firebase/scripts/recipes/`
2. Follow the schema above
3. Assign unique `externalId` (use 10013+)
4. Run the upload script

### Option 2: Expand Web Collection

Continue the web research approach:
- Target: 50-100 high-quality recipes
- Use Skinnytaste (verified nutrition)
- Estimated time: 15-25 hours
- See `firebase/scripts/README.md` for details

---

## Current Recipe List

### Breakfast (4 recipes)
1. **Egg White Muffins with Turkey Bacon** - 144 cal, 20g protein
2. **Chorizo Egg Bites** - 280 cal, 22g protein
3. **Loaded Egg Muffins** - 165 cal, 14g protein
4. **Peanut Butter Protein Pancakes** - 99 cal, 3g protein (per pancake)

### Lunch/Dinner (7 recipes)
1. **Air Fryer Greek Chicken** - 414 cal, 45g protein
2. **Chicken Fajitas** - 299 cal, 39g protein
3. **Grilled Chicken Caprese Salad** - 284 cal, 34g protein
4. **Chicken Lo Mein** - 479 cal, 40g protein
5. **Air Fryer Salmon with Maple Soy Glaze** - 292 cal, 35g protein
6. **Ground Turkey Taco Skillet** - 503 cal, 37g protein
7. **Cilantro Lime Shrimp** - 119 cal, 19g protein

### Snacks (1 recipe)
1. **Vegan Peanut Butter Protein Bars** - 276 cal, 14g protein

---

## Benefits of This Approach

✅ **Quality Control** - Hand-picked recipes with verified nutrition
✅ **Offline Support** - Recipes cached in Firebase work offline
✅ **No API Limits** - Custom recipes don't count against Spoonacular quotas
✅ **Gradual Expansion** - Add more recipes over time as needed
✅ **User Trust** - Show "Curated" badge for premium recipes
✅ **Flexibility** - Can add recipes tailored to your user base

---

## Troubleshooting

### Upload Script Errors

**Error: "Cannot find module 'firebase-admin'"**
```bash
cd firebase/scripts
npm install firebase-admin
```

**Error: "Authentication failed"**
- Check that `GOOGLE_APPLICATION_CREDENTIALS` is set
- Verify the service account key file exists
- Ensure you have Firestore permissions

**Error: "Collection not found"**
- Firestore will auto-create the `custom_recipes` collection
- No manual setup needed

### iOS App Not Showing Recipes

1. **Check Firestore Rules** - Ensure read access is enabled:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /custom_recipes/{recipe} {
      allow read: if true; // Public read access
    }
  }
}
```

2. **Check Network** - Recipes require internet for first fetch
3. **Check Logs** - Look for Firebase errors in Xcode console

---

## Future Enhancements

### Short Term
- [ ] Add "Curated" badge to custom recipe cards
- [ ] Create favorites collection for custom recipes
- [ ] Add recipe ratings and reviews

### Medium Term
- [ ] Expand to 50-100 custom recipes
- [ ] Add seasonal recipe collections
- [ ] User-submitted recipes (moderated)

### Long Term
- [ ] AI-generated meal combinations
- [ ] Personalized recipe recommendations
- [ ] Recipe swaps within meal plans

---

## Files Modified

### iOS App
- ✅ `MealPrepAI/Services/FirebaseRecipeService.swift` - Added dual-collection querying
- ✅ `MealPrepAI/Models/API/FirebaseRecipe.swift` - Added `isCustomRecipe` flag

### Firebase Scripts
- ✅ `firebase/scripts/uploadRecipes.js` - Upload script
- ✅ `firebase/scripts/recipes/breakfast.json` - 4 breakfast recipes
- ✅ `firebase/scripts/recipes/dinner.json` - 7 dinner recipes
- ✅ `firebase/scripts/recipes/snacks.json` - 1 snack recipe
- ✅ `firebase/scripts/README.md` - Detailed documentation

---

## Questions?

If you encounter issues:
1. Check Firebase Console for uploaded recipes
2. Review Xcode logs for Firebase errors
3. Verify Firestore security rules allow read access
4. Ensure app has internet connectivity

**Next Steps:**
1. Upload the 12 recipes: `node firebase/scripts/uploadRecipes.js`
2. Test in the iOS app
3. Decide if you want to expand the collection (optional)
