# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workflow Requirements

1. **Always use the `ios-developer` skill** for every task in this codebase
2. **Build after every task** using the MCP build tool to verify the code compiles
3. **Fix any build errors** before considering a task complete

## Build Commands

This is an iOS SwiftUI app using Xcode. Build and run commands:

```bash
# Build the project
xcodebuild -project MealPrepAI.xcodeproj -scheme MealPrepAI -configuration Debug build

# Run tests
xcodebuild -project MealPrepAI.xcodeproj -scheme MealPrepAI -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run a specific test
xcodebuild -project MealPrepAI.xcodeproj -scheme MealPrepAI -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:MealPrepAITests/MealPrepAITests/example
```

Tests use Swift Testing framework (`import Testing`, `@Test` macros, `#expect()` assertions).

## Architecture

**MVVM with @Observable pattern** - The app follows MVVM architecture with SwiftUI's modern `@Observable` pattern (planned for ViewModels).

### Data Layer (SwiftData)

Nine interconnected `@Model` classes with cascade delete rules:

```
UserProfile (goals, restrictions, allergies, preferences)
    └── MealPlan (weekly)
            └── Day (7 per plan)
                    └── Meal (breakfast, lunch, dinner, snacks)
                            └── Recipe
                                    └── RecipeIngredient
                                            └── Ingredient

GroceryList ← linked to MealPlan
    └── GroceryItem ← linked to Ingredient
```

The `ModelContainer` is configured in `MealPrepAIApp.swift` with all 9 models and injected via `.modelContainer()` modifier.

### Navigation Structure

5-tab `TabView` in `ContentView.swift`:
- **Today** - Daily meals with progress tracking
- **Plan** - Weekly 7-day view with day selector
- **Grocery** - Smart shopping list by category
- **Recipes** - Library with search and favorites
- **Profile** - Settings and dietary preferences

### Design System

`App/DesignSystem.swift` contains the complete design system:
- **Color extensions** - `Color.brandGreen`, `Color.proteinColor`, meal type gradients
- **LinearGradient presets** - `.brandGradient`, `.sunriseGradient` (breakfast), `.freshGradient` (lunch), `.eveningGradient` (dinner), `.skyGradient` (snacks)
- **Design tokens** - `Design.Spacing`, `Design.Radius`, `Design.Shadow`, `Design.Animation`
- **View modifiers** - `.glassCard()`, `.premiumCard()`, `.gradientCard()`, `.floatingButton()`, `.shimmer()`

Reusable UI components in `Views/Components/UIComponents.swift`: `HeroHeaderCard`, `PremiumMealCard`, `NutritionRingCard`, `MacroProgressBar`, `ProgressRing`, `DayPillSelector`, `FloatingPrimaryButton`, `EmptyStateView`, `PremiumGroceryItem`, `PremiumRecipeCard`.

### Enums

`Models/Enums/AppEnums.swift` defines all app enums: `MealType`, `DietaryRestriction`, `Allergy`, `CookingSkill`, `CookingTime`, `CuisineType`, `WeightGoal`, `GroceryCategory`, `MeasurementUnit`, `RecipeComplexity`, `ActivityLevel`, `Gender`. All are `Codable`, `CaseIterable`, and `Identifiable`.

## Implementation Status

Currently in **Phase 1 (Foundation)** - UI scaffolding complete with placeholder data. See `PLAN.md` for roadmap:
- Phase 2: Onboarding flow
- Phase 3: Claude API integration (via backend proxy)
- Phase 4: Meal plan display
- Phase 5: Editing & swapping
- Phase 6: Grocery list logic
- Phase 7: Recipe library features

## Key Design Decisions

- **Local-first with SwiftData** - Offline support, plans cached locally
- **Dual measurements** - Volume (cups/tbsp) + weight (grams) for ingredients
- **Backend proxy for AI** - Users don't need their own API key; app calls a backend that holds the Claude API key
- **Variety engine** - Recipes track `timesUsed` and `lastUsedDate` to enforce diversity

---

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First:** Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan:** Check in before starting implementation
3. **Track Progress:** Mark items complete as you go
4. **Explain Changes:** High-level summary at each step
5. **Document Results:** Add review section to `tasks/todo.md`
6. **Capture Lessons:** Update `tasks/lessons.md` after corrections

## Core Principles

- **Simplicity First:** Make every change as simple as possible. Impact minimal code.
- **No Laziness:** Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact:** Changes should only touch what's necessary. Avoid introducing bugs.
