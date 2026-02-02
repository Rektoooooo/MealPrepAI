/**
 * Firebase Recipe Upload Script
 *
 * Uploads custom recipes to Firestore 'custom_recipes' collection
 *
 * Usage:
 *   node uploadRecipes.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
// Make sure you have GOOGLE_APPLICATION_CREDENTIALS environment variable set
// or provide the service account key file path
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  // Or use: credential: admin.credential.cert(require('./serviceAccountKey.json'))
});

const db = admin.firestore();

// Load recipe files
const loadRecipes = () => {
  const recipesDir = path.join(__dirname, 'recipes');
  const recipeFiles = [
    'breakfast.json',
    'lunch.json',
    'dinner.json',
    'snacks.json'
  ];

  let allRecipes = [];

  for (const file of recipeFiles) {
    const filePath = path.join(recipesDir, file);
    if (fs.existsSync(filePath)) {
      const recipes = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      allRecipes = allRecipes.concat(recipes);
      console.log(`Loaded ${recipes.length} recipes from ${file}`);
    } else {
      console.log(`⚠️  File not found: ${file}`);
    }
  }

  return allRecipes;
};

// Upload recipes to Firestore
const uploadRecipes = async () => {
  try {
    const recipes = loadRecipes();

    if (recipes.length === 0) {
      console.log('❌ No recipes to upload');
      return;
    }

    console.log(`\n📤 Uploading ${recipes.length} recipes to Firestore...\n`);

    // Upload in batches of 500 (Firestore limit)
    const batchSize = 500;
    let uploadedCount = 0;

    for (let i = 0; i < recipes.length; i += batchSize) {
      const batch = db.batch();
      const recipeBatch = recipes.slice(i, i + batchSize);

      for (const recipe of recipeBatch) {
        // Use externalId as document ID for easy reference
        const docRef = db.collection('custom_recipes').doc(recipe.externalId.toString());

        // Add server timestamp
        const recipeData = {
          ...recipe,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        batch.set(docRef, recipeData, { merge: true });
      }

      await batch.commit();
      uploadedCount += recipeBatch.length;
      console.log(`✅ Uploaded ${uploadedCount}/${recipes.length} recipes`);
    }

    console.log(`\n🎉 Successfully uploaded all ${recipes.length} recipes!`);
    console.log(`\nRecipes are now available in the 'custom_recipes' collection`);

  } catch (error) {
    console.error('❌ Error uploading recipes:', error);
    process.exit(1);
  }
};

// Run the upload
uploadRecipes()
  .then(() => {
    console.log('\n✨ Upload complete!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Upload failed:', error);
    process.exit(1);
  });
