# MealPrepAI - Implementation Plan

## Status: ~85% Feature Complete

Last updated: January 29, 2026

---

## Competitor Pain Points We're Solving

| Problem | Competitor | Our Solution | Status |
|---------|-----------|--------------|--------|
| Recipes too complicated | Mealime | "Simple Mode" toggle, complexity scoring | ✅ Done |
| Can't modify meals without resetting grocery list | Mealime | Granular editing with "lock" feature | ⚠️ Partial |
| Can't swap individual ingredients | MealPrepPro | AI ingredient substitution with macro recalculation | ❌ Not started |
| Only uses ounces | MealPrepPro | Dual measurements (cups/tbsp + grams) | ✅ Done |
| No search or favorites | MealPrepPro | Full search, favorites, recipe history | ✅ Done |
| Recipes repeat constantly | Eat This Much | Variety engine tracking usage, enforcing diversity | ✅ Done |
| Odd portions (3/16th tortilla) | Eat This Much | Practical measurement rounding | ✅ Done |
| Can't import recipes | Eat This Much | URL recipe import with AI parsing | ❌ Not started |

---

## Core Features

1. **Onboarding** - 29-step comprehensive flow ✅
2. **AI Meal Plan Generation** - Claude Sonnet 4 via Cloud Functions backend ✅
3. **Daily View** - Today's meals with progress tracking, mark meals eaten ✅
4. **Plan Editing** - Meal swap with variety engine ✅ (ingredient substitution ❌)
5. **Smart Grocery List** - Auto-generated, grouped by category, shopping features ✅

---

## Data Models (SwiftData) ✅

```
UserProfile (goals, restrictions, allergies, preferences)
    └── MealPlan (1-14 days, variable duration)
            └── Day
                    └── Meal (breakfast, lunch, dinner, snacks)
                            └── Recipe
                                    └── RecipeIngredient
                                            └── Ingredient

GroceryList ← linked to MealPlan
    └── GroceryItem ← linked to Ingredient
```

---

## App Navigation (5 Tabs) ✅

```
Tab 1: Today       → Daily meals, progress rings, quick swap
Tab 2: Weekly Plan → Day selector, week navigation, generate plans
Tab 3: Grocery     → Shopping list by category, history, progress
Tab 4: Recipes     → Library, search, favorites, Firebase recipes
Tab 5: Profile     → Settings, goals, dietary preferences, account
```

---

## Implementation Phases

### Phase 1: Foundation ✅ COMPLETE
- SwiftData models (all 9 core models)
- Enum types (13 enums)
- Tab navigation structure
- Design system (colors, typography, spacing, components)
- Reusable UI component library

### Phase 2: Onboarding ✅ COMPLETE
- 29-step onboarding flow (goals, prefs, metrics, culinary, permissions)
- Meal prep setup flow (5 steps for returning users)
- Profile creation and persistence
- Validation logic per step
- Launch screen with sign-in option

### Phase 3: AI Integration ✅ COMPLETE
- Cloud Functions backend (`us-central1-mealprepai-b6ac0`)
- Claude 3.5 Haiku model for generation (cost-efficient, parallel batches)
- Prompt engineering with full user context
- JSON response parsing to SwiftData models
- Meal swap endpoint
- Mock data fallback for development
- Variable plan duration (1-14 days)
- Overlapping plan handling (non-overlapping days migrated to new plan)

### Phase 4: Meal Plan Display ✅ COMPLETE
- Weekly plan view with day selector and week navigation
- Recipe detail view (ingredients, instructions, nutrition)
- Today view with daily progress and nutrition rings
- Mark meals as eaten with HealthKit logging
- Custom calendar with meal plan date range highlighting

### Phase 5: Editing & Swapping ⚠️ PARTIAL
- ✅ Meal swap via AI (exclude recently used recipes)
- ✅ Variety engine (tracks `timesUsed`, `lastUsedDate`)
- ❌ Ingredient substitution with macro recalculation
- ❌ Lock feature to prevent grocery list reset on edit

### Phase 6: Grocery List ✅ COMPLETE
- Smart aggregation from meal plan recipes
- Category grouping (8 categories)
- Check/uncheck items with progress tracking
- Shopping history with completion dates
- Manual item addition
- Share grocery list

### Phase 7: Recipe Library ✅ MOSTLY COMPLETE
- ✅ Search across local + Firebase recipes
- ✅ Favorites with persistence
- ✅ Firebase Spoonacular recipe database with pagination
- ✅ Multi-filter support (diet, category, nutrition ranges)
- ⚠️ Custom recipe creation (UI stub, no data flow)
- ❌ Recipe import from URL

---

## Additional Features Implemented

### Authentication ✅
- Sign in with Apple
- Guest mode
- Account deletion
- State management (unknown, unauthenticated, guest, authenticated)

### HealthKit ✅
- Read weight, height, steps, active energy
- Write meal nutrition (calories, protein, carbs, fat, fiber)
- Toggle per user preference
- Auto-adjust activity level from steps

### Firebase ✅
- App Check (App Attest + Debug provider)
- Firestore recipe database
- Anonymous auth for recipe access
- Recipe image matching disabled for AI recipes (gradient placeholders instead)

### CloudKit ⚠️ PARTIAL
- ModelContainer configured with iCloud container
- Sync manager with status tracking
- Relies on SwiftData's passive CloudKit sync
- No active sync logic

### Notifications ⚠️ PARTIAL
- Local notification manager with read/unread tracking
- Notification permission step in onboarding
- No push notification backend
- No scheduled notification triggers

### Subscription & Paywall ⚠️ PARTIAL
- ✅ Free trial system (first plan free)
- ✅ Paywall UI (monthly $9.99 / annual $59.99)
- ✅ Superwall SDK analytics (paywall funnel tracking)
- ✅ SubscriptionManager service (environment object)
- ❌ StoreKit 2 product fetching & transaction handling
- ❌ Receipt validation
- ❌ Server-side subscription verification

### Design System ✅
- Mint-green + purple accent palette
- Glass morphism modifiers
- Comprehensive component library
- Dark mode support
- Appearance mode settings (system/light/dark)

---

## Remaining Work

### High Priority (Required for App Store)
1. **StoreKit 2 Integration** - Real subscription purchase flow, product catalog, transaction verification
2. **Receipt Validation** - Server-side or on-device receipt verification
3. **Accessibility Audit** - VoiceOver labels, Dynamic Type testing, contrast ratios

### Medium Priority (Post-Launch)
4. **Push Notifications** - APNs setup, meal reminders, trial expiry alerts
5. **Ingredient Substitution** - AI-powered swap with macro recalculation
6. **Custom Recipe Creation** - Complete the data flow from UI stub
7. **CloudKit Active Sync** - Verify cross-device data sync works reliably
8. **Unit & UI Tests** - Test coverage for critical paths

### Low Priority (Future)
9. **Recipe Import from URL** - AI parsing of web recipes
10. **Grocery Lock Feature** - Prevent list reset on meal edits
11. **Advanced Analytics** - Comprehensive event tracking beyond paywall
12. **Widgets** - Home screen widgets for today's meals
13. **Apple Watch** - Quick meal logging companion app

---

## Backend Service ✅

```
Platform: Firebase Cloud Functions (us-central1)
Base URL: https://us-central1-mealprepai-b6ac0.cloudfunctions.net/api

Endpoints:
POST /api/generateMealPlan  → Claude Sonnet 4, returns full plan JSON  ✅
POST /api/swapMeal          → Single meal replacement                  ✅
POST /api/substitute        → Ingredient substitution                  ❌

Security:
- Firebase App Check (App Attest in production)
- Rate limiting per device
- API key held server-side
```

---

## Key Technical Decisions

- **Architecture**: MVVM with @Observable pattern
- **Persistence**: SwiftData with CloudKit backing
- **AI Model**: Claude 3.5 Haiku (cost-efficient, ~12x cheaper than Sonnet)
- **API Approach**: Firebase Cloud Functions proxy
- **Measurements**: Dual display (volume + weight)
- **Offline**: Generated plans cached locally
- **Analytics**: Superwall for paywall funnel, Firebase Analytics available
- **Auth**: Sign in with Apple + guest mode
