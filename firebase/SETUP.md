# Firebase Setup Guide for MealPrepAI

This guide walks you through setting up Firebase for the MealPrepAI recipe system.

## Overview

The Firebase integration provides:
- **Firestore Database**: Stores recipes fetched from Spoonacular
- **Cloud Functions**: Daily scheduled function to collect new recipes
- **Firebase Auth**: Anonymous authentication for iOS app access

## Prerequisites

1. [Firebase CLI](https://firebase.google.com/docs/cli) installed: `npm install -g firebase-tools`
2. [Spoonacular API Key](https://spoonacular.com/food-api) (free tier: 150 calls/day)
3. A Google account for Firebase Console access

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project"
3. Name it: `MealPrepAI` (or your preferred name)
4. Disable Google Analytics (optional, not needed)
5. Click "Create project"

## Step 2: Enable Services

### Firestore Database
1. In Firebase Console, go to **Build > Firestore Database**
2. Click "Create database"
3. Choose "Start in production mode"
4. Select your preferred region (e.g., `us-central1`)
5. Click "Enable"

### Authentication
1. Go to **Build > Authentication**
2. Click "Get started"
3. Enable **Anonymous** sign-in method
4. This allows iOS app to access Firestore without user accounts

### Cloud Functions
1. Go to **Build > Functions**
2. Click "Get started" and upgrade to Blaze (pay-as-you-go) plan
   - Note: You'll still stay within free tier limits, but Functions requires Blaze
   - Set a budget alert at $1 to be safe

## Step 3: Configure iOS App

### Download Config File
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Under "Your apps", click the iOS icon to add an iOS app
3. Enter Bundle ID: `com.yourname.MealPrepAI` (match your Xcode project)
4. Download `GoogleService-Info.plist`
5. Add it to your Xcode project (drag into MealPrepAI folder)

### Add Firebase SDK
1. In Xcode, go to **File > Add Package Dependencies**
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select these products:
   - `FirebaseAuth`
   - `FirebaseFirestore`
4. Click "Add Package"

## Step 4: Deploy Cloud Functions

### Initialize Firebase in Project
```bash
cd /path/to/MealPrepAI/firebase
firebase login
firebase init
# Select existing project
# Choose: Firestore, Functions
```

### Set Spoonacular API Key
```bash
firebase functions:config:set spoonacular.key="YOUR_SPOONACULAR_API_KEY"
```

### Deploy Functions
```bash
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions
```

### Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

## Step 5: Test the Integration

### Manually Trigger Recipe Collection
You can test by running the emulator:
```bash
firebase emulators:start
```

Or trigger manually via Firebase Console:
1. Go to **Functions** in Firebase Console
2. Find `collectRecipes` function
3. Use the "Run" feature in Cloud Scheduler

### Check Firestore
1. Go to **Firestore Database** in Console
2. After first run, you should see a `recipes` collection
3. Each document contains recipe data from Spoonacular

## Step 6: iOS App Configuration

The iOS app is already configured to use Firebase. Ensure:

1. `GoogleService-Info.plist` is in your Xcode project
2. Firebase SDK packages are added (FirebaseAuth, FirebaseFirestore)
3. Build the app to verify no errors

## Free Tier Limits

| Service | Free Limit | Our Usage |
|---------|------------|-----------|
| Firestore Storage | 1 GiB | ~10-20 MB for 2000 recipes |
| Firestore Reads | 50K/day | Depends on app usage |
| Firestore Writes | 20K/day | ~100/day from functions |
| Cloud Functions | 2M invocations/month | 30/month (daily schedule) |
| Spoonacular | 150 calls/day | ~100/day |

## Troubleshooting

### "No such module 'FirebaseCore'"
- Ensure Firebase SDK is added via SPM in Xcode
- Clean build folder (Cmd+Shift+K) and rebuild

### "Spoonacular API key not configured"
- Run: `firebase functions:config:set spoonacular.key="YOUR_KEY"`
- Redeploy functions: `firebase deploy --only functions`

### Firestore permission denied
- Check that Anonymous auth is enabled
- Verify firestore.rules are deployed
- Ensure iOS app is signed in anonymously

### Functions not triggering
- Check Cloud Scheduler in Google Cloud Console
- Verify function deployed successfully
- Check function logs: `firebase functions:log`

## Architecture Summary

```
Spoonacular API (150 calls/day)
        ↓
Cloud Function (daily at 3am UTC)
        ↓
Firestore Database (recipes collection)
        ↓
Firebase SDK (in iOS app)
        ↓
SwiftData Cache (offline support)
```

## Next Steps

After setup:
1. Wait for first daily function run, or trigger manually
2. Recipes will appear in Firestore within minutes
3. iOS app will sync recipes on first launch
4. Pull-to-refresh fetches latest from Firestore
