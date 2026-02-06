# MealPrepAI - App Store Release Fixes

Full audit performed Feb 6, 2026 by 4 specialized agents across 80+ files.

---

## RELEASE BLOCKERS (Apple will reject without these)

- [x] **1. Create PrivacyInfo.xcprivacy** — Apple hard-rejects since Spring 2024. Declared UserDefaults (CA92.1), FileTimestamp (C617.1), DiskSpace (E174.1). `MealPrepAI/PrivacyInfo.xcprivacy`
- [x] **2. Replace placeholder privacy/terms URLs** — `PaywallStepView.swift:168,175` changed from `example.com` to `mealprepai.app/terms` and `mealprepai.app/privacy`
- [x] **3. Remove DISABLED FOR TESTING auth bypass** — `MealPrepAIApp.swift:151-167` commented-out code block removed. Current RootView flow handles all auth states correctly.
- [x] **4. Wrap Developer section in #if DEBUG** — `ProfileView.swift:895` "Clear All Data", "Preview Onboarding", "Load Sample Plan" now hidden from production users
- [x] **5. Add subscription auto-renew disclosure** — `PaywallStepView.swift:153` now includes "Subscription automatically renews unless cancelled at least 24 hours before the end of the current period."
- [x] **6. Implement Apple token revocation on account delete** — `AuthenticationManager.swift` now stores authorization code during sign-in and has `revokeAppleSignIn()` method. `ProfileView.swift:deleteAccountAndResetOnboarding()` calls it. **NOTE: Needs `revokeAppleToken` Cloud Function on Firebase backend.**
- [x] **7. Add SwiftData schema versioning** — Created `SchemaVersioning.swift` with `SchemaV1` + `MealPrepAIMigrationPlan`. ModelContainer uses versioned schema with fallback to local-only on failure.

---

## HIGH PRIORITY (Fix before release for quality)

- [x] **8. Remove 225 print() statements from production** — All 227 print() statements across 19 files wrapped in `#if DEBUG` via automated script.
- [x] **9. Add user-facing error alerts for async operations** — Error alerts added to meal generation, meal swap, add meal, recipe save (AddRecipeSheet, EditRecipeSheet). Fixed dismiss-on-error bug.
- [x] **10. Add accessibilityReduceMotion checks** — reduceMotion checks added to ContentView tab bar, TodayView (GeneratingMealPlanView, SwapMealSheet), RecipesView grid, InsightsView. Added `animateIfAllowed` utility to DesignSystem.
- [x] **11. Fix CloudKitSyncManager deinit crash** — Removed deinit, moved cleanup to explicit `stopMonitoring()` MainActor-isolated method.
- [x] **12. Fix Firestore snapshot listener data race** — Wrapped snapshot listener callback in `Task { @MainActor [weak self] in ... }`.
- [x] **13. Add aps-environment entitlement** — Added `aps-environment` = `development` to `MealPrepAI.entitlements`. Change to `production` for App Store release.
- [ ] **14. Update StoreKit config team ID** — `Configuration.storekit:11` has `"YOUR_TEAM_ID"` placeholder. Replace with actual Apple Developer Team ID. *(Needs your team ID — only affects StoreKit testing, not production)*
- [x] **15. Add accessibility labels to icon-only buttons** — Added `.accessibilityLabel` to grocery menu, stepper buttons, CategoryChip, InsightsView hero card with `.accessibilityElement(children: .combine)`.
- [x] **16. Fix unfiltered @Query performance** — Removed `allIngredients` @Query from RecipesView (now fetches on-demand). Added filtered `@Query(filter: #Predicate<Recipe> { $0.isFavorite })` to ProfileView.
- [x] **17. Fix LaunchScreenView dark mode** — Replaced `Color.white` with `Color(UIColor.systemBackground)`, `Color.black` with `Color.primary` for all text and button elements.
- [x] **18. Fix SubscriptionManager transaction listener leak** — Added cancellation guard in Transaction.updates loop, renamed to stopListening() with proper task cancellation.
- [x] **19. Fix Recipe/Ingredient orphaning** — Created `ModelContext+OrphanCleanup.swift` with `deleteOrphanedRecipes()` and `deleteOrphanedIngredients()`. Called after meal swap (TodayView) and plan generation (MealPlanGenerator).
- [ ] **20. Replace hardcoded font sizes with Dynamic Type** — 236 occurrences of `.font(.system(size:))` across 63 files. Use semantic fonts (`.title`, `.headline`, `.body`) or `.font(.system(.body, design: .rounded))`. Key files: `TodayView.swift:282` (44pt calorie), `ContentView.swift:59,64` (tab bar).
- [x] **21. Create revokeAppleToken Cloud Function** — Created `firebase/functions/src/api/revokeAppleToken.ts` with JWT client secret generation, token exchange, and revocation. Added route in `index.ts`. **NOTE: Requires APPLE_TEAM_ID, APPLE_CLIENT_ID, APPLE_KEY_ID, APPLE_PRIVATE_KEY env vars on Firebase.**

---

## MEDIUM PRIORITY (Fix soon after release)

- [x] **22. Multiple UserProfile records possible** — `OnboardingViewModel.saveProfile()` and `NewOnboardingViewModel.saveProfile()` insert without checking if one exists. Add uniqueness check before insert.
- [x] **23. try? silently swallows JSON encoding failures** — `UserProfile.swift` multiple computed property setters use `try?` for JSONEncoder. Log failures at minimum.
- [x] **24. Timer leak in IngredientSubstitutionSheet** — `IngredientSubstitutionSheet.swift:462` starts timer without storing reference for cleanup. Store timer and invalidate in `onDisappear`.
- [x] **25. No clipboard confirmation toast** — `ShareGroceryListSheet` (line 833), `ShareRecipeSheet` (line 101) copy to clipboard with no visual confirmation. Add brief toast/overlay.
- [x] **26. Tab bar selected color invisible in dark mode** — `ContentView.swift:80` uses `Color(hex: "1C1C1E")` for active tab background, invisible on dark backgrounds. Use adaptive color.
- [x] **27. No network reachability check** — `APIService` makes calls without checking connectivity. User gets generic timeout after 5 min instead of immediate "No internet" message. Use `NWPathMonitor`.
- [x] **28. Touch targets below 44x44pt** — Recipe card add button 34x34pt (`RecipeCardComponents.swift:199`), grocery checkbox 26x26pt (`GroceryListView.swift:455`). Increase to 44pt minimum.
- [x] **29. Color-only state indicators** — Meal dots 8x8pt (`TodayView.swift:230-241`), macro dots 6x6pt (`MealCardComponents.swift:264-281`), today indicator 5x5pt (`WeeklyPlanView.swift:456-463`). Add shape/text differentiation.
- [x] **30. Non-cancellable DispatchQueue.main.asyncAfter** — 5 occurrences (`CalculatingStepView.swift:106,124`, `RecipesView.swift:365`, `IngredientSubstitutionSheet.swift:454,573`). Replace with `Task.sleep` or `.task` modifier.
- [x] **31. RecipesView excessive re-renders** — 4 `@Query` properties + 6 `.onChange` handlers (`RecipesView.swift:8-12,384-398`). Move sync logic to ViewModel, reduce @Query count.
- [x] **32. AsyncImage has no persistent caching** — `ImageComponents.swift:108` uses URLSession default cache. Use dedicated image caching (Kingfisher/SDWebImage or custom URLCache).
- [x] **33. Images not downsampled** — 9 occurrences of `UIImage(data:)` decode at full resolution. Use `preparingThumbnail(of:)` or ImageIO downsampling.
- [x] **34. InsightsView hero card accessibility** *(was already fixed)* — `InsightsView.swift:81-158` weekly adherence card has no accessibility labels or combined element.
- [x] **35. RecipeDetailSheet ingredient swap fails silently** — `RecipeDetailSheet.swift:353-361` sheet doesn't appear if no UserProfile exists. Show feedback.

---

## LOW PRIORITY (Polish / future)

- [x] **36. Duplicate currentMealPlan property** — Removed duplicate from RecipesView.
- [x] **37. Date selector unbounded navigation** — Added bounds checking to TodayView date navigation.
- [x] **38. Grocery sort by raw string** — Added `sortOrder` to GroceryCategory for logical aisle ordering.
- [x] **39. Optional arrays in SwiftData relationships** — Changed to non-optional with default `[]` across all @Model classes.
- [x] **40. No retry logic for API calls** — Added `withRetry` wrapper with exponential backoff (skips 4xx errors).
- [x] **41. Hardcoded API URL** — Created `APIConfiguration` with `#if DEBUG` staging/prod switching.
- [x] **42. Redundant @Query var userProfiles in 9+ views** — Created `UserProfileEnvironment` key, single @Query in ContentView, propagated via `.environment()`.
- [x] **43. Zero accessibilityIdentifier values** — Added identifiers to all key interactive elements across all screens.
- [x] **44. Superwall API key hardcoded** — Moved to `AppConfig` with `#if DEBUG` key switching.

---

## Progress Summary

| Priority | Total | Done | Remaining |
|----------|-------|------|-----------|
| Blockers | 7 | 7 | 0 |
| High | 14 | 12 | 2 |
| Medium | 14 | 14 | 0 |
| Low | 9 | 9 | 0 |
