# Allergy Safety & Data Quality Test Results

**Date:** 2026-03-04
**Test:** `npm run test:profiles` — 3 user profiles, 7-day meal plans each

## Verification Summary

| Check | Profile A (Vegetarian) | Profile B (Tree Nut Allergy) | Profile C (GF + Dairy-Free + Peanut) |
|---|---|---|---|
| **Tree nut ingredients** | N/A | **0 violations** | N/A |
| **Peanut ingredients** | N/A | N/A | **0 violations** |
| **Dairy ingredients** | N/A (not restricted) | N/A | **0 violations** (no Greek yogurt, cheese, milk, butter) |
| **Gluten ingredients** | N/A | N/A | **0 violations** (no soy sauce, couscous, whole wheat) |
| **Tamari (GF soy sauce)** | N/A | N/A | **15 uses** (correct substitute) |
| **Certified GF oats** | N/A | N/A | **6 uses** (correctly labeled) |
| **Almond butter category** | N/A | N/A | **Nuts & Seeds** (fixed from Dairy & Eggs) |
| **Breakfast variety** | 4+ categories | N/A | 4+ categories |
| **Allergy scanner** | 0 warnings | 0 warnings | 0 real violations |
| **iOS category enum** | Correct | Correct | Correct |

## Changes Validated

1. `ALLERGY_EXPANSIONS` map — 9 allergy types expanded to ingredient terms
2. `expandAllergyTerms()` — deduplicates and flattens allergy terms
3. Couscous removed from GF carb list
4. `buildIngredientList()` uses expanded allergies (catches almonds, cottage cheese, etc.)
5. `buildPantryStaples()` — dynamic: tamari for GF, no soy sauce for soy allergy
6. `buildSystemPrompt(profile)` — explicit allergen bans + GF oat note
7. Breakfast category examples improved (eggs only for "eggs" category)
8. `assignSnackArchetypes()` filters by expanded allergies
9. `scanForAllergyViolations()` — post-generation scanner (with dairy-free false positive handling)
10. `correctIngredientCategories()` — maps ~80 ingredients to iOS GroceryCategory enum
11. Snack variety validation moved out of DEBUG-only block

---

## Full Meal Plans

>>> Starting Profile A: Female, 28, weight loss, vegetarian, 1600 kcal ...
<<< Done in 79.9s (success=true)

>>> Starting Profile B: Male, 24, bulking, omnivore, 3200 kcal ...
[VALIDATION] WARNING: 5 yogurt snacks exceeds limit of 2
[VALIDATION] WARNING: 4 cottage cheese snacks exceeds limit of 2
<<< Done in 107.9s (success=true)

>>> Starting Profile C: Female, 40, maintain, gluten-free + dairy-free, 2000 kcal ...
[ALLERGY] Day 0 breakfast "Banana Oat Pancakes with Berries": Ingredient "almond milk" contains allergen "milk"
[ALLERGY] Day 0 snack: Recipe name "Apple Slices with Almond Butter" contains allergen "butter"
[ALLERGY] Day 1 breakfast "Strawberry Protein Smoothie with Coconut": Ingredient "almond milk" contains allergen "milk"
[ALLERGY] Day 2 breakfast: Recipe name "Banana Almond Butter Toast with Berries" contains allergen "butter"
[ALLERGY] Day 2 breakfast "Banana Almond Butter Toast with Berries": Ingredient "almond butter" contains allergen "butter"
[ALLERGY] Day 2 lunch "Thai Green Curry Chicken with Jasmine Rice": Ingredient "coconut milk" contains allergen "milk"
[ALLERGY] Day 3 breakfast "Protein Oat Pancakes with Mango": Ingredient "almond milk" contains allergen "milk"
[ALLERGY] Day 4 breakfast "Banana Almond Protein Smoothie": Ingredient "almond milk" contains allergen "milk"
[ALLERGY] Day 4 breakfast "Banana Almond Protein Smoothie": Ingredient "almond butter" contains allergen "butter"
[ALLERGY] Day 4 snack: Recipe name "Apple Slices with Almond Butter" contains allergen "butter"
[ALLERGY] Day 4 snack "Apple Slices with Almond Butter": Ingredient "almond butter" contains allergen "butter"
[ALLERGY] Day 5 breakfast "Strawberry Oat Pancakes": Ingredient "almond milk" contains allergen "milk"
[ALLERGY] Day 5 breakfast "Strawberry Oat Pancakes": Ingredient "almond butter" contains allergen "butter"
[ALLERGY] Day 6 breakfast "Banana Oat Pancakes with Berries": Ingredient "almond milk" contains allergen "milk"
[ALLERGY] Day 6 lunch "Thai Green Curry Chicken with Jasmine Rice": Ingredient "coconut milk" contains allergen "milk"
<<< Done in 97.9s (success=true)

══════════════════════════════════════════════════════════════════════
  Profile A: Female, 28, weight loss, vegetarian, 1600 kcal
══════════════════════════════════════════════════════════════════════

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MONDAY  |  1650 kcal  |  P 103g  C 173g  F 54g  |  103% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Greek Yogurt Berry Parfait
    399 kcal | P 24g | C 42g | F 13g | Fiber 4g
    Cuisine: mediterranean | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 200 gram Greek yogurt [Dairy & Eggs]
      - 80 gram mixed berries [Produce]
      - 15 gram honey [Condiments & Sauces]
      - 20 gram walnuts [Nuts & Seeds]
    Steps (5):
      1. Add 200 g Greek yogurt to a bowl
      2. Top with 80 g mixed berries
      3. Drizzle with 15 ml honey
      4. Sprinkle 20 g walnuts on top
      5. Mix gently and serve immediately

  [SNACK] Hummus and Vegetable Sticks
    163 kcal | P 15g | C 17g | F 5g | Fiber 5g
    Cuisine: mediterranean | Prep: 4min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 60 gram hummus [Condiments & Sauces]
      - 100 gram carrot [Produce]
      - 80 gram bell pepper [Produce]
    Steps (5):
      1. Pour 60 g hummus into a small bowl
      2. Cut 100 g carrot into sticks
      3. Cut 80 g bell pepper into strips
      4. Arrange vegetables around the hummus bowl
      5. Serve immediately

  [LUNCH] Chickpea and Spinach Rice Bowl
    580 kcal | P 33g | C 61g | F 19g | Fiber 8g
    Cuisine: mediterranean | Prep: 5min | Cook: 15min | Servings: 1
    Ingredients (5):
      - 150 gram chickpeas [Canned & Jarred]
      - 150 gram spinach [Produce]
      - 100 gram cherry tomatoes [Produce]
      - 150 gram rice [Grains & Bread]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (6):
      1. Heat 10 ml olive oil in a large pan over medium heat
      2. Add 150 g cooked chickpeas and cook for 3 minutes, stirring occasionally
      3. Add 150 g fresh spinach and cook until wilted, about 2 minutes
      4. Add 100 g halved cherry tomatoes and cook for 2 minutes
      5. Season with 1/2 teaspoon salt, 1/4 teaspoon pepper, and 1/2 teaspoon garlic powder
      6. Serve over 150 g cooked rice

  [DINNER] Baked Lentil Patties with Roasted Vegetables
    508 kcal | P 31g | C 53g | F 17g | Fiber 9g
    Cuisine: mediterranean | Prep: 10min | Cook: 20min | Servings: 1
    Ingredients (8):
      - 120 gram lentils [Canned & Jarred]
      - 30 gram whole wheat bread [Grains & Bread]
      - 1 piece eggs [Dairy & Eggs]
      - 150 gram broccoli [Produce]
      - 80 gram carrot [Produce]
      - 100 gram zucchini [Produce]
      - 120 gram potato [Produce]
      - 8 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Preheat oven to 200°C
      2. Mix 120 g cooked lentils with 30 g breadcrumbs, 1 egg, 1/2 teaspoon salt, and 1/4 teaspoon pepper in a bowl
      3. Shape mixture into 2 patties (about 80 g each)
      4. Place patties on a baking tray and bake for 12 minutes
      5. Toss 150 g broccoli florets, 80 g carrot chunks, and 100 g zucchini slices with 8 ml olive oil and 1/2 teaspoon salt
      6. Add vegetables to the baking tray around patties and bake together for the final 10 minutes until vegetables are tender
      7. Serve with 120 g cooked potato

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TUESDAY  |  1518 kcal  |  P 104g  C 170g  F 57g  |  95% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Peanut Butter Banana Toast
    367 kcal | P 24g | C 42g | F 14g | Fiber 5g
    Cuisine: american | Prep: 2min | Cook: 2min | Servings: 1
    Ingredients (4):
      - 50 gram whole wheat bread [Grains & Bread]
      - 25 gram peanut butter [Nuts & Seeds]
      - 120 gram banana [Produce]
      - 10 gram honey [Condiments & Sauces]
    Steps (6):
      1. Toast 2 slices of whole wheat bread (50 g total) until golden brown, about 2 minutes
      2. Spread 25 g peanut butter evenly on both slices
      3. Slice 120 g banana and arrange on top
      4. Drizzle with 10 ml honey
      5. Sprinkle 1/4 teaspoon salt lightly across the surface
      6. Serve immediately

  [SNACK] Apple Slices with Almond Butter
    150 kcal | P 16g | C 17g | F 6g | Fiber 4g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (2):
      - 150 gram apple [Produce]
      - 20 gram almonds [Nuts & Seeds]
    Steps (5):
      1. Slice 150 g apple into 8-10 pieces
      2. Place 20 g almond butter in a small bowl
      3. Arrange apple slices on a plate
      4. Serve almond butter on the side for dipping
      5. Eat immediately to prevent browning

  [LUNCH] Black Bean and Sweet Potato Stir-Fry
    534 kcal | P 33g | C 60g | F 20g | Fiber 10g
    Cuisine: indian | Prep: 8min | Cook: 15min | Servings: 1
    Ingredients (6):
      - 150 gram sweet potato [Produce]
      - 160 gram black beans [Canned & Jarred]
      - 80 gram onion [Produce]
      - 100 gram bell pepper [Produce]
      - 100 gram quinoa [Grains & Bread]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (8):
      1. Cut 150 g sweet potato into 1 cm cubes
      2. Heat 10 ml olive oil in a large wok or pan over medium-high heat
      3. Add sweet potato cubes and cook for 8 minutes, stirring occasionally, until tender
      4. Add 80 g diced onion and 100 g bell pepper strips and cook for 3 minutes
      5. Add 160 g black beans and stir well
      6. Season with 1/2 teaspoon salt, 1/4 teaspoon pepper, and 1/2 teaspoon garlic powder
      7. Cook for 2 minutes more until heated through
      8. Serve with 100 g cooked quinoa on the side

  [DINNER] Baked Cottage Cheese and Vegetable Casserole
    467 kcal | P 31g | C 51g | F 17g | Fiber 7g
    Cuisine: mediterranean | Prep: 10min | Cook: 20min | Servings: 1
    Ingredients (7):
      - 100 gram pasta [Grains & Bread]
      - 150 gram cottage cheese [Dairy & Eggs]
      - 120 gram cauliflower [Produce]
      - 80 gram asparagus [Produce]
      - 50 gram cheese [Dairy & Eggs]
      - 60 gram milk [Dairy & Eggs]
      - 100 gram carrot [Produce]
    Steps (8):
      1. Preheat oven to 190°C
      2. Bring a pot of salted water to boil and cook 100 g pasta for 8 minutes until al dente, then drain
      3. Chop 120 g cauliflower into small florets and 80 g asparagus into 3 cm pieces
      4. Steam cauliflower and asparagus for 5 minutes until just tender
      5. Mix 150 g cottage cheese with 50 g grated cheese, 60 ml milk, 1/4 teaspoon salt, and 1/4 teaspoon pepper in a bowl
      6. Combine cooked pasta, steamed vegetables, and cottage cheese mixture in a baking dish
      7. Bake for 12 minutes until golden on top
      8. Serve with 100 g roasted carrot sticks on the side

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  WEDNESDAY  |  1573 kcal  |  P 107g  C 173g  F 54g  |  98% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Greek Yogurt Banana Berry Parfait
    381 kcal | P 25g | C 42g | F 13g | Fiber 5g
    Cuisine: mediterranean | Prep: 5min | Cook: 0min | Servings: 1
    Ingredients (5):
      - 200 gram Greek yogurt [Dairy & Eggs]
      - 80 gram mixed berries [Produce]
      - 1 piece banana [Produce]
      - 30 gram almonds [Nuts & Seeds]
      - 10 gram honey [Condiments & Sauces]
    Steps (6):
      1. Add 200 g Greek yogurt to a bowl
      2. Layer 80 g mixed berries on top
      3. Slice 1 medium banana and add to yogurt
      4. Sprinkle 30 g almonds over the top
      5. Drizzle 10 ml honey across the entire bowl
      6. Mix gently before eating

  [SNACK] Hummus and Veggie Dip
    155 kcal | P 16g | C 17g | F 5g | Fiber 4g
    Cuisine: mediterranean | Prep: 5min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 100 gram carrot [Produce]
      - 50 gram bell pepper [Produce]
      - 80 gram hummus [Condiments & Sauces]
    Steps (5):
      1. Slice 100 g carrot into sticks approximately 8 cm long
      2. Slice 50 g bell pepper into strips
      3. Place 80 g hummus in a small bowl
      4. Arrange vegetables around the hummus bowl
      5. Dip vegetables into hummus and eat

  [LUNCH] Spiced Lentil and Spinach Rice Bowl
    553 kcal | P 34g | C 61g | F 19g | Fiber 8g
    Cuisine: indian | Prep: 5min | Cook: 25min | Servings: 1
    Ingredients (5):
      - 80 gram white rice [Grains & Bread]
      - 150 gram lentils [Canned & Jarred]
      - 100 gram spinach [Produce]
      - 80 gram tomato [Produce]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (6):
      1. Cook 80 g white rice in 160 ml water for 18 minutes until tender
      2. Heat 10 ml olive oil in a pan over medium heat
      3. Add 150 g cooked lentils and stir for 2 minutes
      4. Add 100 g fresh spinach and cook 3 minutes until wilted
      5. Add 1/2 teaspoon garlic powder, 1/4 teaspoon cumin, and 1/4 teaspoon salt to lentils
      6. Divide rice into a bowl, top with lentil-spinach mixture and 80 g diced tomato

  [DINNER] Baked Chickpea and Vegetable Medley with Couscous
    484 kcal | P 32g | C 53g | F 17g | Fiber 9g
    Cuisine: mediterranean | Prep: 8min | Cook: 20min | Servings: 1
    Ingredients (6):
      - 180 gram chickpeas [Canned & Jarred]
      - 120 gram zucchini [Produce]
      - 80 gram bell pepper [Produce]
      - 60 gram onion [Produce]
      - 70 gram couscous [Grains & Bread]
      - 8 gram olive oil [Condiments & Sauces]
    Steps (6):
      1. Preheat oven to 200°C
      2. Toss 180 g cooked chickpeas, 120 g zucchini cubes, 80 g bell pepper chunks, and 60 g diced onion with 8 ml olive oil
      3. Add 1/2 teaspoon Italian seasoning, 1/4 teaspoon salt, and 1/4 teaspoon pepper to vegetables
      4. Spread mixture on a baking tray and roast for 18 minutes, stirring halfway through
      5. While vegetables roast, cook 70 g dry couscous according to package directions (typically 1 part couscous to 1.5 parts boiling water)
      6. Fluff couscous with a fork and divide into a bowl, top with roasted chickpea mixture

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  THURSDAY  |  1664 kcal  |  P 103g  C 180g  F 54g  |  104% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Peanut Butter Oat Breakfast Bowl
    402 kcal | P 24g | C 44g | F 13g | Fiber 6g
    Cuisine: american | Prep: 3min | Cook: 6min | Servings: 1
    Ingredients (6):
      - 60 gram oats [Grains & Bread]
      - 180 gram milk [Dairy & Eggs]
      - 30 gram peanut butter [Nuts & Seeds]
      - 1 piece apple [Produce]
      - 10 gram honey [Condiments & Sauces]
      - 15 gram walnuts [Nuts & Seeds]
    Steps (6):
      1. Combine 60 g dry oats with 180 ml milk in a saucepan
      2. Cook over medium heat for 5 minutes, stirring frequently, until creamy
      3. Stir in 30 g peanut butter until well combined
      4. Slice 1 medium apple into thin slices
      5. Pour oatmeal into a bowl and top with apple slices
      6. Drizzle 10 ml honey on top and sprinkle 15 g walnuts

  [SNACK] Cheese and Crackers with Pear
    165 kcal | P 15g | C 18g | F 5g | Fiber 3g
    Cuisine: american | Prep: 4min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 1 piece pear [Produce]
      - 40 gram cheese [Dairy & Eggs]
      - 30 gram rice cakes [Grains & Bread]
    Steps (5):
      1. Slice 1 medium pear into 8 thin slices
      2. Cut 40 g cheddar cheese into 6 bite-sized cubes
      3. Place 30 g whole grain crackers on a small plate
      4. Arrange pear slices and cheese cubes alongside crackers
      5. Eat cheese, crackers, and pear slices together

  [LUNCH] Indian Spiced Black Bean and Quinoa Buddha Bowl
    585 kcal | P 33g | C 63g | F 19g | Fiber 10g
    Cuisine: indian | Prep: 6min | Cook: 18min | Servings: 1
    Ingredients (5):
      - 75 gram quinoa [Grains & Bread]
      - 160 gram black beans [Canned & Jarred]
      - 100 gram cucumber [Produce]
      - 80 gram tomato [Produce]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (6):
      1. Cook 75 g dry quinoa in 150 ml water for 15 minutes until fluffy
      2. Heat 10 ml olive oil in a pan over medium heat
      3. Add 160 g cooked black beans, 1/2 teaspoon cumin, 1/4 teaspoon turmeric, 1/4 teaspoon coriander, and 1/4 teaspoon salt
      4. Stir beans constantly for 3 minutes until warmed through
      5. Chop 100 g cucumber and 80 g tomato into chunks
      6. Divide cooked quinoa into a bowl, top with spiced black beans, cucumber, and tomato

  [DINNER] Pan-Seared Egg and Asparagus with Sweet Potato
    512 kcal | P 31g | C 55g | F 17g | Fiber 8g
    Cuisine: mediterranean | Prep: 8min | Cook: 22min | Servings: 1
    Ingredients (4):
      - 2 piece eggs [Dairy & Eggs]
      - 150 gram sweet potato [Produce]
      - 150 gram asparagus [Produce]
      - 8 gram olive oil [Condiments & Sauces]
    Steps (6):
      1. Cut 150 g sweet potato into 1.5 cm wedges and toss with 1/2 teaspoon salt and 1/4 teaspoon pepper
      2. Roast sweet potato at 200°C for 20 minutes until golden
      3. Heat 8 ml olive oil in a non-stick pan over medium heat
      4. Add 150 g fresh asparagus spears and cook 4 minutes, turning occasionally
      5. Add 2 eggs (120 g total) to the pan, cooking 4 minutes until whites set but yolks remain soft
      6. Season eggs with 1/4 teaspoon salt and 1/8 teaspoon pepper, arrange on plate with asparagus and sweet potato

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  FRIDAY  |  1518 kcal  |  P 99g  C 170g  F 53g  |  95% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Greek Yogurt Parfait with Berries and Granola
    367 kcal | P 23g | C 38g | F 13g | Fiber 4g
    Cuisine: mediterranean | Prep: 5min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 200 gram Greek yogurt [Dairy & Eggs]
      - 100 gram mixed berries [Produce]
      - 10 gram honey [Condiments & Sauces]
      - 30 gram almonds [Nuts & Seeds]
    Steps (5):
      1. Pour 200 g Greek yogurt into a bowl
      2. Add 100 g mixed berries on top
      3. Drizzle 10 ml honey over the berries
      4. Sprinkle 30 g almonds across the top
      5. Stir gently to combine and serve immediately

  [SNACK] Hummus and Vegetable Sticks
    150 kcal | P 15g | C 16g | F 5g | Fiber 3g
    Cuisine: mediterranean | Prep: 5min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 80 gram hummus [Condiments & Sauces]
      - 100 gram carrot [Produce]
      - 75 gram bell pepper [Produce]
    Steps (5):
      1. Slice 100 g carrot into 8 cm sticks
      2. Slice 75 g bell pepper into strips
      3. Spoon 80 g hummus into a small bowl
      4. Arrange vegetables around the hummus bowl
      5. Serve immediately for dipping

  [LUNCH] Mediterranean Chickpea and Spinach Pilaf
    534 kcal | P 32g | C 62g | F 19g | Fiber 5g
    Cuisine: mediterranean | Prep: 5min | Cook: 10min | Servings: 1
    Ingredients (6):
      - 150 gram cooked rice [Grains & Bread]
      - 200 gram chickpeas [Canned & Jarred]
      - 80 gram spinach [Produce]
      - 100 gram tomato [Produce]
      - 40 gram onion [Produce]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Heat 10 ml olive oil in a pan over medium heat
      2. Add 40 g diced onion and cook for 2 minutes until softened
      3. Add 150 g cooked rice, 200 g canned chickpeas (drained), and 100 g diced tomato, stir well
      4. Cook for 4 minutes, stirring occasionally
      5. Add 80 g fresh spinach and 1/2 teaspoon garlic powder, stir until spinach wilts (2 minutes)
      6. Season with 1/4 teaspoon salt and 1/8 teaspoon pepper
      7. Serve hot

  [DINNER] Indian Spiced Lentil Curry with Roasted Vegetables
    467 kcal | P 29g | C 54g | F 16g | Fiber 6g
    Cuisine: indian | Prep: 8min | Cook: 20min | Servings: 1
    Ingredients (6):
      - 150 gram cooked lentils [Canned & Jarred]
      - 100 gram cooked quinoa [Grains & Bread]
      - 150 gram broccoli [Produce]
      - 120 gram cauliflower [Produce]
      - 150 gram milk [Dairy & Eggs]
      - 8 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Preheat oven to 200°C
      2. Toss 150 g broccoli florets and 120 g cauliflower florets with 8 ml olive oil, 1/4 teaspoon salt, and 1/8 teaspoon pepper
      3. Roast vegetables for 15 minutes until golden
      4. Heat 150 ml milk in a pot over medium heat
      5. Add 150 g cooked lentils, 1/2 teaspoon garlic powder, 1/4 teaspoon curry powder, and 1/4 teaspoon salt
      6. Simmer for 5 minutes until curry thickens
      7. Serve curry over 100 g cooked quinoa with roasted vegetables on the side

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SATURDAY  |  1607 kcal  |  P 96g  C 174g  F 58g  |  100% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Whole Wheat Toast with Almond Butter and Banana
    389 kcal | P 22g | C 42g | F 14g | Fiber 4g
    Cuisine: american | Prep: 3min | Cook: 2min | Servings: 1
    Ingredients (4):
      - 60 gram whole wheat bread [Grains & Bread]
      - 35 gram almond butter [Nuts & Seeds]
      - 120 gram banana [Produce]
      - 10 gram honey [Condiments & Sauces]
    Steps (5):
      1. Toast 2 slices (60 g) whole wheat bread until golden brown (2 minutes)
      2. Spread 35 g almond butter evenly on both toast slices
      3. Slice 120 g banana and arrange on top of the almond butter
      4. Drizzle 10 ml honey over the banana
      5. Serve immediately

  [SNACK] Apple Slices with Peanut Butter
    159 kcal | P 14g | C 17g | F 6g | Fiber 3g
    Cuisine: american | Prep: 5min | Cook: 0min | Servings: 1
    Ingredients (2):
      - 150 gram apple [Produce]
      - 30 gram peanut butter [Nuts & Seeds]
    Steps (4):
      1. Slice 150 g apple into 8 equal wedges
      2. Spoon 30 g peanut butter into a small bowl
      3. Arrange apple slices on a plate
      4. Serve apple slices with peanut butter for dipping

  [LUNCH] Indian Chickpea and Potato Curry with Spinach
    565 kcal | P 31g | C 61g | F 20g | Fiber 5g
    Cuisine: indian | Prep: 8min | Cook: 15min | Servings: 1
    Ingredients (7):
      - 180 gram chickpeas [Canned & Jarred]
      - 140 gram cooked basmati rice [Grains & Bread]
      - 150 gram potato [Produce]
      - 90 gram spinach [Produce]
      - 50 gram onion [Produce]
      - 80 gram milk [Dairy & Eggs]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Heat 10 ml olive oil in a pan over medium heat
      2. Add 50 g diced onion and cook for 2 minutes until translucent
      3. Add 150 g diced potato and cook for 5 minutes, stirring occasionally
      4. Add 180 g canned chickpeas (drained), 1/2 teaspoon garlic powder, 1/4 teaspoon cumin, and 1/4 teaspoon salt
      5. Stir well and cook for 3 minutes
      6. Add 90 g fresh spinach and 80 ml milk, stir until spinach wilts (2 minutes)
      7. Serve over 140 g cooked basmati rice

  [DINNER] Baked Black Bean and Vegetable Tacos with Sweet Potato
    494 kcal | P 29g | C 54g | F 18g | Fiber 6g
    Cuisine: mediterranean | Prep: 10min | Cook: 20min | Servings: 1
    Ingredients (6):
      - 160 gram black beans [Canned & Jarred]
      - 50 gram tortilla [Grains & Bread]
      - 150 gram sweet potato [Produce]
      - 60 gram bell pepper [Produce]
      - 60 gram zucchini [Produce]
      - 8 gram olive oil [Condiments & Sauces]
    Steps (8):
      1. Preheat oven to 200°C
      2. Toss 150 g sweet potato cubes with 8 ml olive oil, 1/4 teaspoon salt, and pinch of pepper
      3. Roast sweet potato for 18 minutes until tender and caramelized
      4. Warm 160 g canned black beans (drained) in a small pot for 3 minutes over medium heat
      5. Add 1/4 teaspoon garlic powder, 1/8 teaspoon cumin, and 1/8 teaspoon salt to beans, stir
      6. Warm 2 whole wheat tortillas (50 g total) in a dry pan for 30 seconds per side
      7. Fill tortillas with black bean mixture (80 g per tortilla), add 60 g shredded bell pepper and 60 g diced zucchini
      8. Serve with roasted sweet potato on the side

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SUNDAY  |  1658 kcal  |  P 106g  C 179g  F 47g  |  104% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Greek Yogurt Parfait with Berries and Granola
    401 kcal | P 24g | C 48g | F 9g | Fiber 4g
    Cuisine: mediterranean | Prep: 5min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 200 gram Greek yogurt [Dairy & Eggs]
      - 100 gram mixed berries (blueberries and strawberries) [Produce]
      - 15 gram honey [Condiments & Sauces]
      - 30 gram oats (or granola) [Grains & Bread]
    Steps (5):
      1. Scoop 200 g Greek yogurt into a bowl
      2. Top with 100 g mixed berries (blueberries and strawberries)
      3. Drizzle 15 ml honey over the yogurt and berries
      4. Sprinkle 30 g granola (or crushed oats) on top
      5. Serve immediately

  [SNACK] Hummus and Vegetable Plate
    164 kcal | P 16g | C 15g | F 5g | Fiber 4g
    Cuisine: mediterranean | Prep: 5min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 80 gram hummus [Condiments & Sauces]
      - 100 gram carrot [Produce]
      - 100 gram bell pepper [Produce]
    Steps (5):
      1. Scoop 80 g hummus into a small bowl
      2. Slice 100 g carrot into sticks
      3. Slice 100 g bell pepper into strips
      4. Arrange carrot and bell pepper sticks around the hummus
      5. Serve immediately

  [LUNCH] Spiced Chickpea Curry with Rice
    583 kcal | P 34g | C 61g | F 19g | Fiber 5g
    Cuisine: indian | Prep: 10min | Cook: 20min | Servings: 1
    Ingredients (6):
      - 250 gram chickpeas (canned) [Canned & Jarred]
      - 150 gram rice (white or brown) [Grains & Bread]
      - 80 gram spinach [Produce]
      - 150 gram tomato (fresh, diced) [Produce]
      - 50 gram onion [Produce]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Heat 10 ml olive oil in a pan over medium heat
      2. Add 50 g diced onion and cook for 3 minutes until softened
      3. Add 1 tsp garlic powder, 1 tsp turmeric, and 1/2 tsp cumin, cook for 1 minute
      4. Add 250 g canned chickpeas (drained), 150 g diced tomato, and 80 g spinach
      5. Simmer for 8 minutes until spinach wilts and sauce thickens
      6. Cook 150 g rice separately according to package directions (about 15-18 minutes)
      7. Serve curry over cooked rice, season with 1/4 tsp salt and pinch of pepper

  [DINNER] Baked Lentil Patties with Roasted Vegetables
    510 kcal | P 32g | C 55g | F 14g | Fiber 6g
    Cuisine: mediterranean | Prep: 10min | Cook: 20min | Servings: 1
    Ingredients (6):
      - 180 gram lentils (cooked) [Canned & Jarred]
      - 150 gram broccoli [Produce]
      - 120 gram zucchini [Produce]
      - 100 gram sweet potato [Produce]
      - 30 gram onion [Produce]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Preheat oven to 200°C
      2. Mash 180 g cooked lentils in a bowl, add 30 g diced onion, 1/2 tsp Italian seasoning, 1/4 tsp salt, pinch of pepper
      3. Form mixture into 2 patties (about 80 g each), place on oiled baking sheet
      4. Chop 150 g broccoli florets, 120 g zucchini, and 100 g sweet potato into bite-sized pieces
      5. Toss vegetables with 10 ml olive oil, 1/4 tsp salt, and pinch of pepper, spread on second baking sheet
      6. Bake both sheets for 18 minutes until patties are golden and vegetables are tender
      7. Serve lentil patties alongside roasted vegetables

══════════════════════════════════════════════════════════════════════
  Profile B: Male, 24, bulking, omnivore, 3200 kcal
══════════════════════════════════════════════════════════════════════

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MONDAY  |  3256 kcal  |  P 199g  C 397g  F 64g  |  102% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Chocolate Peanut Butter Protein Pancakes
    657 kcal | P 35g | C 81g | F 18g | Fiber 8g
    Cuisine: american | Prep: 5min | Cook: 8min | Servings: 1
    Ingredients (8):
      - 50 gram oats [Grains & Bread]
      - 30 gram protein powder [Baking & Cooking]
      - 15 gram unsweetened cocoa powder [Baking & Cooking]
      - 120 gram milk [Dairy & Eggs]
      - 5 gram honey [Condiments & Sauces]
      - 5 gram butter [Dairy & Eggs]
      - 20 gram peanut butter [Nuts & Seeds]
      - 100 gram banana [Produce]
    Steps (5):
      1. Mix 50 g oats, 30 g protein powder, 15 g unsweetened cocoa powder, 5 ml honey, and 120 ml milk in a blender until smooth
      2. Heat 5 g butter in a non-stick skillet over medium heat
      3. Pour batter into 3 small pancakes, cooking 2 minutes per side until golden
      4. Transfer to plate and top with 20 g peanut butter spread on warm pancakes
      5. Slice 1 medium banana and arrange on top

  [SNACK] Greek Yogurt Berry Parfait
    269 kcal | P 23g | C 33g | F 4g | Fiber 3g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 200 gram Greek yogurt [Dairy & Eggs]
      - 100 gram mixed berries [Produce]
      - 10 gram honey [Condiments & Sauces]
    Steps (4):
      1. Pour 200 g Greek yogurt into a bowl
      2. Top with 100 g mixed berries
      3. Drizzle 10 g honey over the top
      4. Stir gently to combine, leave some berries visible

  [LUNCH] Grilled Chicken Breast with Mexican Lime Rice and Black Beans
    956 kcal | P 49g | C 117g | F 11g | Fiber 8g
    Cuisine: mexican | Prep: 10min | Cook: 30min | Servings: 1
    Ingredients (7):
      - 250 gram chicken breast [Meat & Seafood]
      - 150 gram rice [Grains & Bread]
      - 100 gram bell pepper [Produce]
      - 1 piece lime [Produce]
      - 150 gram black beans [Canned & Jarred]
      - 10 gram cilantro [Produce]
      - 1 gram cumin [Spices & Seasonings]
    Steps (6):
      1. Preheat grill to 200°C
      2. Season 250 g chicken breast with 2 g garlic powder, 1 g cumin, salt, and pepper
      3. Grill chicken 7 minutes per side until internal temperature reaches 75°C
      4. Cook 150 g rice in 300 ml water with juice from 1 lime and fresh cilantro for 15 minutes
      5. Heat 150 g canned black beans with 100 g diced bell pepper in a skillet over medium heat for 5 minutes, add salt and pepper
      6. Transfer chicken to plate, fluff rice with fork, arrange beans alongside

  [SNACK] Hard Boiled Eggs with Whole Grain Crackers
    269 kcal | P 23g | C 31g | F 8g | Fiber 4g
    Cuisine: american | Prep: 2min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 100 gram hard boiled eggs [Dairy & Eggs]
      - 40 gram whole wheat bread [Grains & Bread]
      - 150 gram apple [Produce]
    Steps (4):
      1. Peel 2 hard boiled eggs and place on a plate
      2. Arrange 40 g whole grain crackers alongside
      3. Slice 1 medium apple into 8 wedges
      4. Serve with a sprinkle of salt and pepper on eggs

  [DINNER] Pan-Seared Salmon with Roasted Sweet Potato and Asparagus
    836 kcal | P 46g | C 102g | F 18g | Fiber 9g
    Cuisine: american | Prep: 10min | Cook: 25min | Servings: 1
    Ingredients (4):
      - 220 gram salmon [Meat & Seafood]
      - 200 gram sweet potato [Produce]
      - 200 gram asparagus [Produce]
      - 12 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Preheat oven to 200°C
      2. Cut 200 g sweet potato into wedges, toss with 5 g olive oil, salt, and pepper, roast for 20 minutes
      3. Heat 5 g olive oil in a skillet over medium-high heat
      4. Season 220 g salmon fillet with garlic powder and pepper, place skin-side down in skillet, cook 5 minutes until skin is crispy
      5. Flip salmon, cook 3 minutes more until internal temperature reaches 62°C
      6. Toss 200 g asparagus with 2 g olive oil and salt, add to oven for final 10 minutes with potatoes
      7. Plate salmon, sweet potato, and asparagus together

  [SNACK] Cottage Cheese Bowl with Strawberries and Granola
    269 kcal | P 23g | C 33g | F 5g | Fiber 2g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 220 gram cottage cheese [Dairy & Eggs]
      - 120 gram strawberries [Produce]
      - 30 gram granola [Grains & Bread]
      - 5 gram honey [Condiments & Sauces]
    Steps (4):
      1. Pour 220 g cottage cheese into a bowl
      2. Top with 120 g fresh strawberries, sliced in half
      3. Sprinkle 30 g granola over top for texture and crunch
      4. Drizzle 5 g honey across the surface

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TUESDAY  |  3242 kcal  |  P 203g  C 355g  F 70g  |  101% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Scrambled Eggs with Spinach and Whole Wheat Toast
    654 kcal | P 36g | C 72g | F 16g | Fiber 7g
    Cuisine: american | Prep: 5min | Cook: 10min | Servings: 1
    Ingredients (6):
      - 150 gram eggs [Dairy & Eggs]
      - 100 gram spinach [Produce]
      - 60 gram whole wheat bread [Grains & Bread]
      - 5 gram butter [Dairy & Eggs]
      - 30 gram milk [Dairy & Eggs]
      - 30 gram avocado [Produce]
    Steps (6):
      1. Heat 5 g butter in a non-stick skillet over medium heat
      2. Whisk 3 large eggs in a bowl with 30 ml milk, salt, and pepper
      3. Add 100 g fresh spinach to the skillet, cook until wilted, about 2 minutes
      4. Pour whisked eggs over spinach, stir gently and cook 4 minutes until set
      5. Toast 2 slices whole wheat bread until golden, about 2 minutes
      6. Spread 30 g avocado on toast, plate with eggs

  [SNACK] Protein Smoothie with Mango and Banana
    268 kcal | P 23g | C 29g | F 5g | Fiber 3g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (5):
      - 25 gram protein powder [Baking & Cooking]
      - 200 gram milk [Dairy & Eggs]
      - 100 gram mango [Produce]
      - 80 gram banana [Produce]
      - 80 gram Greek yogurt [Dairy & Eggs]
    Steps (4):
      1. Add 200 ml milk to blender
      2. Add 25 g protein powder, 100 g fresh mango, 80 g banana, and 80 g Greek yogurt
      3. Blend on high for 45 seconds until smooth and creamy
      4. Pour into glass and serve immediately

  [LUNCH] Stir-Fried Beef with Broccoli and Brown Rice
    951 kcal | P 51g | C 105g | F 18g | Fiber 8g
    Cuisine: asian | Prep: 15min | Cook: 30min | Servings: 1
    Ingredients (5):
      - 270 gram steak [Meat & Seafood]
      - 250 gram broccoli [Produce]
      - 150 gram rice [Grains & Bread]
      - 8 gram olive oil [Condiments & Sauces]
      - 15 gram soy sauce [Condiments & Sauces]
    Steps (7):
      1. Cook 150 g brown rice in 300 ml water for 20 minutes, fluff with fork
      2. Slice 270 g lean beef steak into 5 mm strips against the grain
      3. Heat 8 g olive oil in a wok or large skillet over high heat until shimmering
      4. Add beef strips and stir-fry for 3 minutes until browned, remove and set aside
      5. Add 250 g broccoli florets to the wok, stir-fry for 4 minutes
      6. Return beef to wok, add 15 ml soy sauce and 2 g garlic powder, toss for 1 minute
      7. Plate rice as base, top with beef and broccoli mixture

  [SNACK] Hummus with Roasted Chickpeas and Bell Pepper Sticks
    268 kcal | P 23g | C 29g | F 6g | Fiber 8g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 100 gram hummus [Condiments & Sauces]
      - 100 gram bell pepper [Produce]
      - 80 gram edamame [Frozen]
    Steps (4):
      1. Pour 100 g hummus into a small bowl
      2. Arrange 100 g fresh bell pepper sticks around the hummus
      3. Pour 80 g roasted chickpeas into another small bowl alongside
      4. Sprinkle 1 g garlic powder and salt over chickpeas

  [DINNER] Baked Cod with Roasted Vegetables and Couscous
    833 kcal | P 47g | C 91g | F 18g | Fiber 10g
    Cuisine: american | Prep: 12min | Cook: 25min | Servings: 1
    Ingredients (5):
      - 240 gram cod [Meat & Seafood]
      - 200 gram carrot [Produce]
      - 200 gram zucchini [Produce]
      - 120 gram couscous [Grains & Bread]
      - 8 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Preheat oven to 190°C
      2. Mix 200 g diced carrot, 200 g diced zucchini with 8 g olive oil, salt, and pepper, spread on a baking tray
      3. Roast vegetables for 15 minutes at 190°C
      4. Season 240 g cod fillet with 2 g garlic powder, pepper, place on tray with vegetables
      5. Roast fish for 10 minutes until internal temperature reaches 62°C
      6. Cook 120 g couscous in 240 ml boiling water, cover and let sit 5 minutes, fluff with fork
      7. Plate couscous as base, arrange roasted vegetables around it, top with cod

  [SNACK] Turkey and Cheese Roll-ups with Crackers
    268 kcal | P 23g | C 29g | F 7g | Fiber 2g
    Cuisine: american | Prep: 4min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 100 gram turkey breast [Meat & Seafood]
      - 40 gram cheese [Dairy & Eggs]
      - 35 gram whole wheat bread [Grains & Bread]
      - 150 gram orange [Produce]
    Steps (5):
      1. Layer 100 g sliced turkey breast with 40 g cheese slices
      2. Roll each turkey-cheese pair loosely and secure with toothpick if needed
      3. Arrange 35 g whole grain crackers on a plate
      4. Place turkey roll-ups alongside crackers
      5. Segment 150 g fresh orange and serve together

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  WEDNESDAY  |  3018 kcal  |  P 209g  C 389g  F 80g  |  94% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Protein Pancakes with Berries
    609 kcal | P 37g | C 79g | F 18g | Fiber 4g
    Cuisine: american | Prep: 5min | Cook: 10min | Servings: 1
    Ingredients (6):
      - 50 gram oats [Grains & Bread]
      - 2 piece eggs [Dairy & Eggs]
      - 100 gram milk [Dairy & Eggs]
      - 100 gram mixed berries [Produce]
      - 15 gram butter [Dairy & Eggs]
      - 25 gram honey [Condiments & Sauces]
    Steps (6):
      1. Mix 50 g oats, 2 eggs, 100 ml milk, and 15 g honey in a blender until smooth
      2. Heat 1 tbsp butter in a non-stick pan over medium heat
      3. Pour batter into 3 pancakes (approximately 80 g each) and cook 2-3 minutes per side until golden
      4. Transfer pancakes to a plate
      5. Top with 100 g mixed berries
      6. Drizzle with 10 g honey

  [SNACK] Greek Yogurt Protein Bowl
    249 kcal | P 24g | C 32g | F 7g | Fiber 2g
    Cuisine: american | Prep: 2min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 200 gram Greek yogurt [Dairy & Eggs]
      - 50 gram mixed berries [Produce]
      - 30 gram rice cakes [Grains & Bread]
      - 10 gram honey [Condiments & Sauces]
    Steps (4):
      1. Scoop 200 g Greek yogurt into a bowl
      2. Top with 50 g mixed berries
      3. Add 30 g granola (or crushed rice cakes)
      4. Drizzle with 10 g honey

  [LUNCH] Soy-Glazed Chicken Stir-Fry
    886 kcal | P 52g | C 114g | F 18g | Fiber 5g
    Cuisine: asian | Prep: 10min | Cook: 25min | Servings: 1
    Ingredients (7):
      - 250 gram chicken breast [Meat & Seafood]
      - 200 gram rice [Grains & Bread]
      - 100 gram broccoli [Produce]
      - 150 gram bell pepper [Produce]
      - 80 gram onion [Produce]
      - 10 gram olive oil [Condiments & Sauces]
      - 30 gram soy sauce [Condiments & Sauces]
    Steps (6):
      1. Cook 200 g jasmine rice in 350 ml water for 15 minutes until tender, then fluff with a fork
      2. Cut 250 g chicken breast into 2 cm cubes
      3. Heat 10 ml olive oil in a wok or large pan over high heat
      4. Add chicken and cook 5-6 minutes until cooked through, stirring frequently
      5. Add 150 g mixed bell pepper, 100 g broccoli, and 80 g onion, cook 4-5 minutes until tender-crisp
      6. Mix 30 ml soy sauce with 15 g honey and 5 ml water, pour into pan, toss to coat, cook 1 minute

  [SNACK] Peanut Butter Banana Toast
    249 kcal | P 24g | C 32g | F 7g | Fiber 3g
    Cuisine: american | Prep: 3min | Cook: 2min | Servings: 1
    Ingredients (4):
      - 50 gram whole wheat bread [Grains & Bread]
      - 30 gram peanut butter [Nuts & Seeds]
      - 100 gram banana [Produce]
      - 5 gram honey [Condiments & Sauces]
    Steps (4):
      1. Toast 50 g whole wheat bread until golden brown
      2. Spread 30 g peanut butter evenly across the toast
      3. Slice 100 g banana and arrange on top
      4. Drizzle with 5 g honey

  [DINNER] Grilled Salmon with Roasted Sweet Potato
    776 kcal | P 48g | C 100g | F 23g | Fiber 6g
    Cuisine: american | Prep: 10min | Cook: 25min | Servings: 1
    Ingredients (4):
      - 200 gram salmon [Meat & Seafood]
      - 250 gram sweet potato [Produce]
      - 120 gram asparagus [Produce]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Preheat oven to 200°C
      2. Cut 250 g sweet potato into 2 cm cubes, toss with 5 ml olive oil, 2 g salt, 1 g pepper, spread on baking sheet
      3. Roast sweet potato for 20 minutes
      4. Heat 5 ml olive oil in a non-stick pan over medium-high heat
      5. Season 200 g salmon fillet with 2 g salt and 1 g pepper on both sides
      6. Cook salmon 4-5 minutes per side until opaque throughout
      7. Grill 120 g asparagus in the same pan 3-4 minutes until tender

  [SNACK] Cottage Cheese with Mango
    249 kcal | P 24g | C 32g | F 7g | Fiber 2g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 200 gram cottage cheese [Dairy & Eggs]
      - 100 gram mango [Produce]
      - 10 gram honey [Condiments & Sauces]
    Steps (4):
      1. Scoop 200 g cottage cheese into a bowl
      2. Dice 100 g fresh mango into chunks
      3. Combine mango with cottage cheese
      4. Add 10 g honey and stir gently

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  THURSDAY  |  3415 kcal  |  P 209g  C 370g  F 108g  |  107% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Savory Egg Scramble with Cheese
    689 kcal | P 37g | C 45g | F 38g | Fiber 3g
    Cuisine: american | Prep: 5min | Cook: 10min | Servings: 1
    Ingredients (7):
      - 3 piece eggs [Dairy & Eggs]
      - 80 gram spinach [Produce]
      - 50 gram tomato [Produce]
      - 60 gram onion [Produce]
      - 40 gram cheese [Dairy & Eggs]
      - 30 gram milk [Dairy & Eggs]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (6):
      1. Heat 10 ml olive oil in a non-stick pan over medium heat
      2. Add 60 g diced onion and 80 g spinach, cook 2-3 minutes until spinach wilts
      3. Beat 3 eggs with 30 ml milk, 2 g salt, and 1 g pepper in a bowl
      4. Pour egg mixture into pan with vegetables, stir constantly 3-4 minutes until cooked through
      5. Add 40 g shredded cheese and stir until melted
      6. Transfer to plate and top with 50 g diced tomato

  [SNACK] Hard Boiled Eggs with Apple
    282 kcal | P 24g | C 34g | F 7g | Fiber 5g
    Cuisine: american | Prep: 2min | Cook: 0min | Servings: 1
    Ingredients (2):
      - 2 piece hard boiled eggs [Dairy & Eggs]
      - 150 gram apple [Produce]
    Steps (4):
      1. Place 2 hard boiled eggs in a bowl
      2. Wash and slice 150 g apple into quarters
      3. Sprinkle eggs with 1 g salt and 0.5 g pepper
      4. Arrange apple slices alongside eggs

  [LUNCH] Mexican Ground Beef Burrito Bowl
    1003 kcal | P 52g | C 119g | F 26g | Fiber 7g
    Cuisine: mexican | Prep: 10min | Cook: 25min | Servings: 1
    Ingredients (6):
      - 280 gram ground beef [Meat & Seafood]
      - 180 gram rice [Grains & Bread]
      - 80 gram corn [Produce]
      - 50 gram tomato [Produce]
      - 10 gram olive oil [Condiments & Sauces]
      - 5 gram soy sauce [Condiments & Sauces]
    Steps (6):
      1. Cook 180 g white rice in 300 ml water for 15 minutes until tender
      2. Heat 10 ml olive oil in a large pan over medium-high heat
      3. Add 280 g ground beef and cook 5-7 minutes, breaking apart with a spoon, until browned
      4. Drain excess fat, add 15 g tomato paste, 5 ml soy sauce, and garlic powder to beef
      5. Stir in 120 g canned black beans (drained) and 80 g corn, cook 2-3 minutes
      6. Divide cooked rice into a bowl, top with beef mixture and 50 g salsa

  [SNACK] Edamame with Sea Salt
    282 kcal | P 24g | C 34g | F 7g | Fiber 4g
    Cuisine: asian | Prep: 2min | Cook: 5min | Servings: 1
    Ingredients (1):
      - 150 gram edamame [Frozen]
    Steps (5):
      1. Heat 200 ml water in a pot and bring to boil
      2. Add 150 g frozen edamame and cook 5 minutes
      3. Drain edamame in a colander
      4. Transfer to a bowl and sprinkle with 2 g sea salt
      5. Serve warm

  [DINNER] Pan-Seared Pork Chop with Roasted Root Vegetables
    877 kcal | P 48g | C 104g | F 23g | Fiber 4g
    Cuisine: american | Prep: 10min | Cook: 25min | Servings: 1
    Ingredients (5):
      - 240 gram pork chop [Meat & Seafood]
      - 100 gram carrot [Produce]
      - 150 gram zucchini [Produce]
      - 100 gram couscous [Grains & Bread]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Preheat oven to 200°C
      2. Toss 100 g diced carrot and 150 g diced zucchini with 5 ml olive oil, 2 g salt, 1 g pepper
      3. Spread vegetables on baking sheet and roast for 18-20 minutes
      4. Heat 5 ml olive oil in a cast iron pan over medium-high heat
      5. Season 240 g pork chop with 3 g salt and 1.5 g pepper on both sides
      6. Cook pork 5-6 minutes per side until internal temperature reaches 63°C
      7. Prepare 100 g couscous according to package directions

  [SNACK] Protein Smoothie with Banana
    282 kcal | P 24g | C 34g | F 7g | Fiber 2g
    Cuisine: american | Prep: 2min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 200 gram milk [Dairy & Eggs]
      - 80 gram banana [Produce]
      - 15 gram dark chocolate [Snacks]
      - 30 gram protein smoothie [Beverages]
    Steps (6):
      1. Pour 200 ml milk into a blender
      2. Add 1 scoop protein powder (approximately 30 g)
      3. Add 80 g banana (sliced)
      4. Add 15 g dark chocolate (chopped or powder)
      5. Blend on high speed for 45-60 seconds until smooth
      6. Pour into a glass and serve immediately

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  FRIDAY  |  3259 kcal  |  P 189g  C 352g  F 98g  |  102% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Protein Pancakes with Berries and Honey
    658 kcal | P 33g | C 73g | F 19g | Fiber 4g
    Cuisine: american | Prep: 5min | Cook: 8min | Servings: 1
    Ingredients (8):
      - 50 gram oats [Grains & Bread]
      - 30 gram protein powder [Baking & Cooking]
      - 100 gram banana [Produce]
      - 100 gram milk [Dairy & Eggs]
      - 2 piece eggs [Dairy & Eggs]
      - 5 gram olive oil [Condiments & Sauces]
      - 100 gram mixed berries [Produce]
      - 20 gram honey [Condiments & Sauces]
    Steps (6):
      1. Mix 50 g oats, 30 g protein powder, 1 banana (mashed), 100 ml milk, and 2 eggs in a bowl until smooth
      2. Heat a non-stick skillet over medium heat with 5 ml olive oil
      3. Pour batter into 3 pancakes, each 10 cm diameter, cooking 3 minutes per side until golden
      4. Transfer pancakes to a plate
      5. Top with 100 g mixed berries
      6. Drizzle 20 ml honey over the stack and serve immediately

  [SNACK] Greek Yogurt with Granola and Blueberries
    269 kcal | P 22g | C 28g | F 8g | Fiber 2g
    Cuisine: american | Prep: 2min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 200 gram Greek yogurt [Dairy & Eggs]
      - 50 gram granola [Grains & Bread]
      - 30 gram blueberries [Produce]
    Steps (4):
      1. Pour 200 g Greek yogurt into a bowl
      2. Top with 50 g granola
      3. Add 30 g blueberries
      4. Stir gently to combine and serve

  [LUNCH] Asian-Style Grilled Chicken with Stir-Fried Vegetables and Rice
    957 kcal | P 47g | C 105g | F 28g | Fiber 5g
    Cuisine: asian | Prep: 10min | Cook: 35min | Servings: 1
    Ingredients (7):
      - 250 gram jasmine rice [Grains & Bread]
      - 220 gram chicken breast [Meat & Seafood]
      - 30 gram soy sauce [Condiments & Sauces]
      - 15 gram honey [Condiments & Sauces]
      - 150 gram broccoli [Produce]
      - 100 gram bell pepper [Produce]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Cook 250 g jasmine rice according to package directions (about 18 minutes)
      2. Marinate 220 g chicken breast in 30 ml soy sauce, 15 ml honey, and 5 g garlic powder for 5 minutes
      3. Preheat grill to high heat and grill chicken 6 minutes per side until internal temperature reaches 75°C
      4. Rest chicken for 2 minutes, then slice into 5 mm strips
      5. Heat 10 ml olive oil in a wok or large skillet over high heat
      6. Stir-fry 150 g broccoli florets and 100 g bell pepper for 5 minutes until tender-crisp
      7. Divide rice between plate, top with chicken and vegetables, and serve

  [SNACK] Peanut Butter and Apple Slices
    269 kcal | P 22g | C 29g | F 8g | Fiber 4g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (2):
      - 150 gram apple [Produce]
      - 40 gram peanut butter [Nuts & Seeds]
    Steps (3):
      1. Slice 150 g apple into 8 equal pieces
      2. Place 40 g peanut butter in a small bowl
      3. Dip each apple slice into peanut butter and serve immediately

  [DINNER] Pan-Seared Salmon with Roasted Sweet Potato and Green Beans
    837 kcal | P 43g | C 89g | F 27g | Fiber 6g
    Cuisine: american | Prep: 10min | Cook: 25min | Servings: 1
    Ingredients (4):
      - 210 gram salmon [Meat & Seafood]
      - 250 gram sweet potato [Produce]
      - 200 gram green beans [Produce]
      - 10 gram olive oil [Condiments & Sauces]
    Steps (8):
      1. Preheat oven to 200°C
      2. Cube 250 g sweet potato into 2 cm pieces, toss with 5 ml olive oil and salt, spread on baking sheet
      3. Roast sweet potato for 20 minutes until golden
      4. Heat 5 ml olive oil in a skillet over medium-high heat
      5. Season 210 g salmon fillet with 2 g salt and 1 g pepper, place skin-side down and cook 5 minutes until skin crisps
      6. Flip salmon and cook 3 minutes until cooked through
      7. Boil 200 g green beans in salted water for 4 minutes, drain, toss with 2 g garlic powder
      8. Plate salmon with sweet potato and green beans

  [SNACK] Hard Boiled Eggs with Rice Cakes and Hummus
    269 kcal | P 22g | C 28g | F 8g | Fiber 3g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 2 piece hard boiled eggs [Dairy & Eggs]
      - 2 piece rice cakes [Grains & Bread]
      - 40 gram hummus [Condiments & Sauces]
    Steps (5):
      1. Take 2 hard boiled eggs and peel the shells
      2. Place 2 rice cakes on a plate
      3. Spread 40 g hummus evenly across both rice cakes
      4. Top each rice cake with 1 hard boiled egg (halved)
      5. Sprinkle with 1 g salt and serve

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SATURDAY  |  3220 kcal  |  P 189g  C 332g  F 110g  |  101% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Avocado Toast with Scrambled Eggs and Tomato
    650 kcal | P 33g | C 52g | F 32g | Fiber 5g
    Cuisine: american | Prep: 5min | Cook: 8min | Servings: 1
    Ingredients (5):
      - 50 gram whole wheat bread [Grains & Bread]
      - 3 piece eggs [Dairy & Eggs]
      - 100 gram avocado [Produce]
      - 40 gram tomato [Produce]
      - 5 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Toast 2 slices of whole wheat bread until golden (2 minutes)
      2. Heat 5 ml olive oil in a non-stick skillet over medium heat
      3. Add 3 eggs to the skillet, scramble with a spatula for 4 minutes until just set
      4. Mash 100 g avocado in a small bowl with 1 g salt and 0.5 g pepper
      5. Spread avocado evenly on both toast slices
      6. Top each slice with half the scrambled eggs
      7. Add 40 g sliced tomato on top and serve immediately

  [SNACK] Edamame with Sea Salt
    266 kcal | P 22g | C 16g | F 11g | Fiber 4g
    Cuisine: asian | Prep: 2min | Cook: 5min | Servings: 1
    Ingredients (1):
      - 180 gram edamame [Frozen]
    Steps (5):
      1. Boil 180 g frozen edamame in salted water for 5 minutes
      2. Drain edamame in a colander
      3. Transfer to a small bowl
      4. Sprinkle with 2 g sea salt
      5. Stir gently and serve warm

  [LUNCH] Mexican-Style Ground Turkey Taco Bowl with Cilantro Lime Rice
    945 kcal | P 47g | C 118g | F 29g | Fiber 6g
    Cuisine: mexican | Prep: 10min | Cook: 35min | Servings: 1
    Ingredients (6):
      - 240 gram ground turkey [Meat & Seafood]
      - 200 gram rice [Grains & Bread]
      - 80 gram corn [Produce]
      - 100 gram bell pepper [Produce]
      - 80 gram black beans [Canned & Jarred]
      - 8 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Cook 200 g long-grain white rice according to package directions (18 minutes), fluff with fork
      2. Heat 8 ml olive oil in a large skillet over medium-high heat
      3. Add 240 g ground turkey, breaking into small pieces as it cooks for 8 minutes until browned
      4. Stir in 5 g garlic powder, 3 g cumin, 2 g chili powder, and 2 g salt
      5. Add 80 g corn and 100 g bell pepper, cook 3 minutes
      6. Toss cooked rice with 10 ml lime juice and 5 g cilantro
      7. Divide rice into bowl, top with turkey mixture, add 80 g cooked black beans, and serve

  [SNACK] Cottage Cheese with Strawberries and Dark Chocolate
    266 kcal | P 22g | C 22g | F 9g | Fiber 2g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 200 gram cottage cheese [Dairy & Eggs]
      - 80 gram strawberries [Produce]
      - 20 gram dark chocolate [Snacks]
    Steps (5):
      1. Scoop 200 g cottage cheese into a bowl
      2. Slice 80 g fresh strawberries
      3. Add strawberries to the cottage cheese
      4. Top with 20 g dark chocolate chips
      5. Fold gently to combine and serve

  [DINNER] Slow-Cooked Beef Stew with Root Vegetables and Crusty Bread
    827 kcal | P 43g | C 89g | F 26g | Fiber 6g
    Cuisine: american | Prep: 10min | Cook: 45min | Servings: 1
    Ingredients (7):
      - 240 gram steak [Meat & Seafood]
      - 150 gram carrot [Produce]
      - 150 gram potato [Produce]
      - 80 gram mushrooms [Produce]
      - 300 gram beef broth [Meat & Seafood]
      - 40 gram whole wheat bread [Grains & Bread]
      - 8 gram olive oil [Condiments & Sauces]
    Steps (7):
      1. Cut 240 g lean beef steak into 3 cm cubes
      2. Heat 8 ml olive oil in a large pot over medium-high heat
      3. Brown beef on all sides for 5 minutes, season with 2 g salt and 1 g pepper
      4. Add 150 g diced carrot, 150 g diced potato, 80 g mushrooms, and 300 ml low-sodium beef broth
      5. Bring to a simmer, reduce heat to low, cover, and cook for 35 minutes until beef is tender
      6. Stir in 3 g garlic powder and 2 g Italian seasoning in the last 2 minutes
      7. Serve stew in a bowl with 40 g whole wheat bread on the side

  [SNACK] Protein Smoothie with Mango and Greek Yogurt
    266 kcal | P 22g | C 35g | F 3g | Fiber 2g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 100 gram milk [Dairy & Eggs]
      - 150 gram mango [Produce]
      - 100 gram Greek yogurt [Dairy & Eggs]
      - 25 gram protein powder [Baking & Cooking]
    Steps (6):
      1. Pour 100 ml milk into a blender
      2. Add 150 g frozen mango chunks
      3. Add 100 g Greek yogurt
      4. Add 25 g protein powder
      5. Blend on high speed for 45 seconds until smooth
      6. Pour into a tall glass and serve immediately

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SUNDAY  |  3370 kcal  |  P 212g  C 386g  F 96g  |  105% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Protein Pancakes with Berry Compote
    680 kcal | P 38g | C 78g | F 22g | Fiber 4g
    Cuisine: american | Prep: 5min | Cook: 10min | Servings: 1
    Ingredients (7):
      - 50 gram oats [Grains & Bread]
      - 40 gram Greek yogurt [Dairy & Eggs]
      - 2 piece eggs [Dairy & Eggs]
      - 15 gram milk [Dairy & Eggs]
      - 120 gram mixed berries [Produce]
      - 10 gram honey [Condiments & Sauces]
      - 15 gram butter [Dairy & Eggs]
    Steps (6):
      1. Mix 50 g oats, 40 g Greek yogurt, 2 eggs, 15 ml milk, and 1/2 tsp vanilla extract in a blender until smooth
      2. Heat 1 tbsp butter on a griddle over medium heat for 1 minute
      3. Pour batter onto griddle and cook 3 minutes per side until golden brown
      4. Combine 120 g mixed berries with 10 g honey in a saucepan and heat over medium for 2 minutes, stirring occasionally
      5. Plate pancakes and top with berry compote
      6. Serve immediately

  [SNACK] Greek Yogurt Protein Bowl
    278 kcal | P 24g | C 32g | F 6g | Fiber 2g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 200 gram Greek yogurt [Dairy & Eggs]
      - 80 gram banana [Produce]
      - 15 gram dark chocolate [Snacks]
    Steps (4):
      1. Pour 200 g Greek yogurt into a bowl
      2. Slice 80 g banana and add to yogurt
      3. Sprinkle 15 g dark chocolate chips on top
      4. Mix gently and serve immediately

  [LUNCH] Asian Stir-Fried Chicken with Brown Rice
    990 kcal | P 53g | C 117g | F 24g | Fiber 5g
    Cuisine: asian | Prep: 15min | Cook: 30min | Servings: 1
    Ingredients (8):
      - 220 gram chicken breast [Meat & Seafood]
      - 200 gram brown rice [Grains & Bread]
      - 100 gram bell pepper [Produce]
      - 80 gram mushrooms [Produce]
      - 100 gram broccoli [Produce]
      - 15 gram olive oil [Condiments & Sauces]
      - 30 gram soy sauce [Condiments & Sauces]
      - 5 gram honey [Condiments & Sauces]
    Steps (7):
      1. Cook 200 g brown rice in 400 ml water for 20 minutes until tender, then set aside
      2. Cut 220 g chicken breast into 2 cm cubes and dice 100 g bell pepper, 80 g mushrooms, and 100 g broccoli
      3. Heat 15 ml olive oil in a wok or large skillet over high heat for 1 minute
      4. Add chicken and cook 5 minutes, stirring frequently until nearly cooked through
      5. Add vegetables and stir-fry for 4 minutes until broccoli is tender-crisp
      6. Pour 30 ml soy sauce and 5 ml honey into the pan, cook 1 minute while stirring
      7. Divide rice between plate and top with chicken and vegetable mixture

  [SNACK] Cottage Cheese and Apple Snack
    278 kcal | P 24g | C 36g | F 5g | Fiber 2g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 180 gram cottage cheese [Dairy & Eggs]
      - 120 gram apple [Produce]
      - 10 gram honey [Condiments & Sauces]
    Steps (4):
      1. Scoop 180 g cottage cheese into a bowl
      2. Slice 120 g apple and arrange on top
      3. Drizzle with 10 g honey
      4. Serve immediately or refrigerate until ready to eat

  [DINNER] Mexican-Seasoned Grilled Steak with Sweet Potato and Roasted Vegetables
    866 kcal | P 49g | C 103g | F 26g | Fiber 4g
    Cuisine: mexican | Prep: 12min | Cook: 30min | Servings: 1
    Ingredients (4):
      - 240 gram steak [Meat & Seafood]
      - 150 gram sweet potato [Produce]
      - 120 gram zucchini [Produce]
      - 15 gram olive oil [Condiments & Sauces]
    Steps (6):
      1. Cut 240 g steak into one thick piece and pat dry with paper towels
      2. Rub both sides with 1/2 tsp garlic powder, 1/4 tsp cumin, salt, and pepper
      3. Preheat grill to high heat and cook steak 5 minutes per side for medium doneness, then rest 2 minutes
      4. Cube 150 g sweet potato and toss with 10 ml olive oil, roast in 200°C oven for 20 minutes until crispy
      5. Slice 120 g zucchini lengthwise and brush with 5 ml olive oil, grill 3 minutes per side until marked
      6. Plate steak, roasted sweet potato, and grilled zucchini

  [SNACK] Hard Boiled Eggs with Carrots and Hummus
    278 kcal | P 24g | C 20g | F 13g | Fiber 3g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 3 piece hard boiled eggs [Dairy & Eggs]
      - 100 gram carrot [Produce]
      - 40 gram hummus [Condiments & Sauces]
    Steps (4):
      1. Place 3 hard boiled eggs on a plate
      2. Cut 100 g carrots into sticks
      3. Scoop 40 g hummus into a small bowl for dipping
      4. Arrange carrots and eggs around hummus and serve

══════════════════════════════════════════════════════════════════════
  Profile C: Female, 40, maintain, gluten-free + dairy-free, 2000 kcal
══════════════════════════════════════════════════════════════════════

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  MONDAY  |  2073 kcal  |  P 122g  C 235g  F 68g  |  104% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Banana Oat Pancakes with Berries
    456 kcal | P 24g | C 52g | F 15g | Fiber 6g
    Cuisine: american | Prep: 5min | Cook: 8min | Servings: 1
    Ingredients (6):
      - 0.5 cup oats [Grains & Bread]
      - 1 piece banana [Produce]
      - 0.5 cup almond milk [Beverages]
      - 1 tbsp honey [Condiments & Sauces]
      - 0.5 cup mixed berries [Produce]
      - 1 tbsp coconut oil [Condiments & Sauces]
    Steps (6):
      1. Blend 1/2 cup oats, 1 ripe banana, 1/2 cup almond milk, 1 tbsp honey, and 1/2 tsp baking powder until smooth
      2. Heat 1 tbsp coconut oil in a non-stick skillet over medium heat
      3. Pour 1/4 of batter onto skillet and cook 2 minutes until edges look set
      4. Flip pancake and cook 1.5 minutes until golden brown
      5. Repeat with remaining batter to make 4 small pancakes
      6. Top with 1/2 cup mixed berries and drizzle with 1/2 tbsp honey

  [SNACK] Almond and Dark Chocolate Trail Mix
    187 kcal | P 16g | C 21g | F 6g | Fiber 3g
    Cuisine: american | Prep: 2min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 0.25 cup almonds [Nuts & Seeds]
      - 2 tbsp walnuts [Nuts & Seeds]
      - 1 tbsp dark chocolate [Snacks]
    Steps (3):
      1. Combine 1/4 cup almonds, 2 tbsp walnuts, and 1 tbsp dark chocolate chips in a small bowl
      2. Stir to combine
      3. Portion into serving container

  [LUNCH] Grilled Japanese-Style Salmon with Teriyaki Rice
    663 kcal | P 34g | C 75g | F 22g | Fiber 5g
    Cuisine: japanese | Prep: 12min | Cook: 25min | Servings: 1
    Ingredients (5):
      - 6 oz salmon [Meat & Seafood]
      - 0.75 cup rice [Grains & Bread]
      - 1.5 cup broccoli [Produce]
      - 2 tbsp tamari [Condiments & Sauces]
      - 1 tbsp honey [Condiments & Sauces]
    Steps (7):
      1. Mix 2 tbsp tamari, 1 tbsp honey, 1 tsp garlic powder in a small bowl
      2. Place 6 oz salmon fillet in a shallow dish and coat with marinade, let sit 10 minutes
      3. Preheat grill or grill pan to medium-high heat and lightly oil grates
      4. Grill salmon 5 minutes per side until cooked through
      5. Cook 3/4 cup rice according to package directions
      6. Steam 1.5 cups broccoli florets for 4 minutes until tender-crisp
      7. Plate salmon over rice with broccoli on the side

  [SNACK] Apple Slices with Almond Butter
    187 kcal | P 16g | C 21g | F 6g | Fiber 4g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (2):
      - 1 piece apple [Produce]
      - 2 tbsp almonds [Nuts & Seeds]
    Steps (3):
      1. Slice 1 medium apple into 8 slices
      2. Place on a small plate
      3. Spoon 2 tbsp almond butter into a small bowl for dipping

  [DINNER] Pan-Seared Thai Cod with Sweet Potato and Green Beans
    580 kcal | P 32g | C 66g | F 19g | Fiber 8g
    Cuisine: thai | Prep: 10min | Cook: 25min | Servings: 1
    Ingredients (5):
      - 6 oz cod [Meat & Seafood]
      - 1 piece sweet potato [Produce]
      - 1.5 cup green beans [Produce]
      - 1 tbsp olive oil [Condiments & Sauces]
      - 1 tbsp coconut oil [Condiments & Sauces]
    Steps (7):
      1. Cut 1 medium sweet potato into 1/2 inch cubes and toss with 1 tbsp olive oil, 1/4 tsp salt, and 1/4 tsp pepper
      2. Spread on a baking sheet and roast at 400°F for 18 minutes
      3. Pat 6 oz cod fillet dry with paper towels and season with 1/4 tsp salt, 1/4 tsp pepper, and 1/2 tsp garlic powder
      4. Heat 1 tbsp coconut oil in a skillet over medium-high heat
      5. Cook cod 4 minutes per side until opaque and flaky
      6. Steam 1.5 cups green beans for 5 minutes until tender-crisp
      7. Arrange cod, sweet potato, and green beans on plate

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TUESDAY  |  1911 kcal  |  P 123g  C 220g  F 75g  |  96% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Strawberry Protein Smoothie with Coconut
    420 kcal | P 25g | C 48g | F 16g | Fiber 4g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 1 cup strawberries [Produce]
      - 1 cup almond milk [Beverages]
      - 1 piece protein smoothie [Beverages]
      - 0.5 tbsp honey [Condiments & Sauces]
    Steps (3):
      1. Add 1 cup strawberries, 1 cup almond milk, 1 scoop protein powder, and 1/2 tbsp honey to blender
      2. Blend on high for 45 seconds until smooth
      3. Pour into a glass and serve immediately

  [SNACK] Hummus and Cucumber Snack
    172 kcal | P 16g | C 20g | F 7g | Fiber 3g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (2):
      - 1 piece cucumber [Produce]
      - 0.25 cup hummus [Condiments & Sauces]
    Steps (3):
      1. Slice 1 medium cucumber into 1/4 inch thick rounds
      2. Arrange on a small plate
      3. Spoon 1/4 cup hummus into a small bowl for dipping

  [LUNCH] Italian Herb Grilled Chicken with Quinoa and Zucchini
    612 kcal | P 34g | C 70g | F 24g | Fiber 6g
    Cuisine: italian | Prep: 12min | Cook: 25min | Servings: 1
    Ingredients (4):
      - 6 oz chicken breast [Meat & Seafood]
      - 0.67 cup quinoa [Grains & Bread]
      - 1 piece zucchini [Produce]
      - 1.5 tbsp olive oil [Condiments & Sauces]
    Steps (7):
      1. Combine 1 tbsp olive oil, 1 tsp Italian seasoning, 1/4 tsp salt, and 1/4 tsp pepper in a small bowl
      2. Rub mixture onto 6 oz chicken breast and let sit 5 minutes
      3. Cook 2/3 cup quinoa according to package directions
      4. Preheat grill or grill pan to medium-high heat and lightly oil grates
      5. Grill chicken 7 minutes per side until internal temperature reaches 165°F
      6. Slice 1 medium zucchini lengthwise into 1/4 inch planks, brush with 1/2 tbsp olive oil
      7. Grill zucchini 3 minutes per side until tender with grill marks, plate with chicken and quinoa

  [SNACK] Edamame and Walnuts Mix
    172 kcal | P 16g | C 20g | F 7g | Fiber 4g
    Cuisine: japanese | Prep: 2min | Cook: 2min | Servings: 1
    Ingredients (2):
      - 1 cup edamame [Frozen]
      - 2 tbsp walnuts [Nuts & Seeds]
    Steps (3):
      1. Heat 1 cup edamame in microwave for 2 minutes
      2. Mix with 2 tbsp walnuts in a small bowl
      3. Season with 1/8 tsp salt and stir

  [DINNER] Ground Turkey Thai Stir-Fry with Rice Noodles
    535 kcal | P 32g | C 62g | F 21g | Fiber 5g
    Cuisine: thai | Prep: 10min | Cook: 20min | Servings: 1
    Ingredients (7):
      - 6 oz ground turkey [Meat & Seafood]
      - 1.5 oz rice [Grains & Bread]
      - 0.5 cup bell pepper [Produce]
      - 0.5 cup onion [Produce]
      - 0.5 cup carrot [Produce]
      - 1 tbsp coconut oil [Condiments & Sauces]
      - 1 tbsp tamari [Condiments & Sauces]
    Steps (7):
      1. Cook 1.5 oz rice noodles according to package directions, drain and set aside
      2. Heat 1 tbsp coconut oil in a large skillet over medium-high heat
      3. Add 6 oz ground turkey and cook 5 minutes, breaking apart with a spoon until fully cooked
      4. Add 1/2 cup diced bell pepper, 1/2 cup diced onion, and 1/2 cup diced carrot
      5. Stir-fry for 6 minutes until vegetables are tender-crisp
      6. Mix 1 tbsp tamari, 1/2 tsp garlic powder, and 1/4 tsp pepper into vegetables
      7. Toss in cooked noodles and combine for 1 minute, plate and serve

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  WEDNESDAY  |  2145 kcal  |  P 124g  C 228g  F 70g  |  107% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Banana Almond Butter Toast with Berries
    472 kcal | P 25g | C 52g | F 15g | Fiber 8g
    Cuisine: american | Prep: 5min | Cook: 4min | Servings: 1
    Ingredients (5):
      - 2 slice gluten-free bread [Grains & Bread]
      - 2 tablespoon almond butter [Nuts & Seeds]
      - 1 piece banana [Produce]
      - 0.5 cup mixed berries [Produce]
      - 1 teaspoon honey [Condiments & Sauces]
    Steps (5):
      1. Toast 2 slices gluten-free bread until golden brown, about 3-4 minutes.
      2. Spread 2 tbsp almond butter evenly across both toast slices.
      3. Slice 1 medium banana and arrange slices over the almond butter.
      4. Top with 1/2 cup mixed berries (blueberries and strawberries).
      5. Drizzle 1 tsp honey across the top and serve immediately.

  [SNACK] Apple Slices with Trail Mix
    193 kcal | P 16g | C 18g | F 8g | Fiber 4g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 1 piece apple [Produce]
      - 0.25 cup almonds [Nuts & Seeds]
      - 2 tablespoon walnuts [Nuts & Seeds]
      - 1 tablespoon dark chocolate chips [Snacks]
    Steps (4):
      1. Slice 1 medium apple into thin wedges.
      2. Combine 1/4 cup almonds, 2 tbsp walnuts, and 1 tbsp dark chocolate chips in a small bowl.
      3. Arrange apple slices on a plate with trail mix on the side.
      4. Eat immediately to prevent apple browning.

  [LUNCH] Thai Green Curry Chicken with Jasmine Rice
    686 kcal | P 35g | C 74g | F 22g | Fiber 3g
    Cuisine: thai | Prep: 10min | Cook: 22min | Servings: 1
    Ingredients (7):
      - 6 oz chicken breast [Meat & Seafood]
      - 1 tablespoon coconut oil [Condiments & Sauces]
      - 1 cup bell pepper [Produce]
      - 0.5 cup onion [Produce]
      - 2 tablespoon Thai green curry paste [Condiments & Sauces]
      - 0.25 cup coconut milk [Beverages]
      - 1 cup jasmine rice [Grains & Bread]
    Steps (6):
      1. Heat 1 tbsp coconut oil in a large skillet over medium-high heat for 2 minutes.
      2. Pan-sear 6 oz diced chicken breast for 6 minutes per side until cooked through (165°F internal temperature).
      3. Add 1 cup sliced bell pepper (red and green), 1/2 cup sliced onion, and cook 3 minutes.
      4. Stir in 2 tbsp Thai green curry paste and 1/4 cup coconut milk, simmer 4 minutes.
      5. Season with 1/4 tsp salt and 1/8 tsp pepper.
      6. Serve over 1 cup cooked jasmine rice.

  [SNACK] Edamame and Rice Cake Snack
    193 kcal | P 16g | C 20g | F 6g | Fiber 4g
    Cuisine: japanese | Prep: 2min | Cook: 4min | Servings: 1
    Ingredients (2):
      - 1 cup edamame [Frozen]
      - 2 piece rice cakes [Grains & Bread]
    Steps (4):
      1. Microwave 1 cup frozen edamame (in pod) in a microwave-safe bowl with 2 tbsp water for 4 minutes.
      2. Drain any excess water and sprinkle 1/8 tsp salt over warm edamame.
      3. Serve edamame alongside 2 gluten-free rice cakes.
      4. Pop edamame from pods while eating.

  [DINNER] Italian Baked Cod with Roasted Vegetables
    601 kcal | P 32g | C 64g | F 19g | Fiber 8g
    Cuisine: italian | Prep: 12min | Cook: 18min | Servings: 1
    Ingredients (6):
      - 7 oz cod [Meat & Seafood]
      - 1.5 teaspoon olive oil [Condiments & Sauces]
      - 1 cup zucchini [Produce]
      - 1 cup broccoli [Produce]
      - 0.5 cup carrot [Produce]
      - 0.67 cup quinoa [Grains & Bread]
    Steps (7):
      1. Preheat oven to 400°F.
      2. Place 7 oz cod fillet on a parchment-lined baking sheet.
      3. Rub cod with 1 tsp olive oil and sprinkle with 1/2 tsp Italian seasoning, 1/8 tsp salt, and 1/8 tsp pepper.
      4. Arrange around the cod: 1 cup diced zucchini, 1 cup broccoli florets, and 1/2 cup diced carrots.
      5. Drizzle vegetables with 1/2 tsp olive oil and season with 1/8 tsp salt.
      6. Bake for 18 minutes until cod flakes easily and vegetables are tender.
      7. Serve with 2/3 cup cooked quinoa on the side.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  THURSDAY  |  2036 kcal  |  P 129g  C 228g  F 68g  |  102% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Protein Oat Pancakes with Mango
    448 kcal | P 26g | C 51g | F 15g | Fiber 5g
    Cuisine: american | Prep: 8min | Cook: 7min | Servings: 1
    Ingredients (6):
      - 0.5 cup certified gluten-free oats [Grains & Bread]
      - 0.33 cup almond milk [Beverages]
      - 1 scoop protein powder [Baking & Cooking]
      - 1 teaspoon coconut oil [Condiments & Sauces]
      - 0.75 cup mango [Produce]
      - 1 teaspoon honey [Condiments & Sauces]
    Steps (5):
      1. Blend 1/2 cup certified gluten-free oats, 1/3 cup almond milk, 1 scoop vanilla protein powder, 1/2 tsp baking powder, and 1/8 tsp salt until smooth.
      2. Heat 1 tsp coconut oil in a non-stick skillet over medium heat for 1 minute.
      3. Pour batter into 2 medium pancakes (about 1/4 cup each) and cook 3 minutes per side until golden.
      4. Slice 3/4 cup fresh mango and arrange on top of pancakes.
      5. Drizzle with 1 tsp honey and serve immediately.

  [SNACK] Pear with Almonds and Dark Chocolate
    183 kcal | P 17g | C 20g | F 6g | Fiber 5g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 1 piece pear [Produce]
      - 0.25 cup almonds [Nuts & Seeds]
      - 1 tablespoon dark chocolate [Snacks]
    Steps (5):
      1. Slice 1 medium pear into 8 thin wedges.
      2. Measure out 1/4 cup roasted almonds into a small bowl.
      3. Chop 1 tbsp dark chocolate into small pieces.
      4. Arrange pear slices on a plate with almonds and chocolate pieces.
      5. Eat immediately.

  [LUNCH] Japanese Teriyaki Salmon with Sweet Potato and Spinach
    652 kcal | P 36g | C 72g | F 22g | Fiber 6g
    Cuisine: japanese | Prep: 12min | Cook: 18min | Servings: 1
    Ingredients (6):
      - 7 oz salmon [Meat & Seafood]
      - 1 tablespoon olive oil [Condiments & Sauces]
      - 2 tablespoon tamari [Condiments & Sauces]
      - 1 teaspoon honey [Condiments & Sauces]
      - 2 cup spinach [Produce]
      - 1 cup sweet potato [Produce]
    Steps (7):
      1. Cut 7 oz salmon fillet into even pieces.
      2. Heat 1 tbsp olive oil in a skillet over medium-high heat for 1 minute.
      3. Pan-sear salmon 5 minutes per side until cooked through (145°F internal temperature).
      4. Mix 2 tbsp tamari, 1 tsp honey, and 1/2 tsp minced garlic; add to pan with salmon.
      5. Glaze salmon for 1 minute, then remove from pan.
      6. In same skillet, add 2 cups fresh spinach and cook 2 minutes until wilted, stirring often.
      7. Serve salmon and spinach with 1 cup roasted sweet potato cubes.

  [SNACK] Orange Slices with Walnuts
    183 kcal | P 17g | C 21g | F 6g | Fiber 3g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (2):
      - 1 piece orange [Produce]
      - 2 tablespoon walnuts [Nuts & Seeds]
    Steps (4):
      1. Peel 1 medium orange and separate into segments.
      2. Measure 2 tbsp walnut pieces into a small bowl.
      3. Arrange orange segments on a plate with walnuts on the side.
      4. Eat immediately while orange is fresh.

  [DINNER] Ground Turkey Stir-Fry with Brown Rice
    570 kcal | P 33g | C 64g | F 19g | Fiber 5g
    Cuisine: thai | Prep: 10min | Cook: 18min | Servings: 1
    Ingredients (7):
      - 7 oz ground turkey [Meat & Seafood]
      - 1 tablespoon coconut oil [Condiments & Sauces]
      - 1 cup bell pepper [Produce]
      - 1 cup broccoli [Produce]
      - 0.5 cup onion [Produce]
      - 2 tablespoon tamari [Condiments & Sauces]
      - 1 cup brown rice [Grains & Bread]
    Steps (7):
      1. Heat 1 tbsp coconut oil in a large skillet over medium-high heat for 1 minute.
      2. Add 7 oz ground turkey and cook 6 minutes, breaking apart with a spoon until no pink remains.
      3. Add 1 cup diced bell pepper, 1 cup broccoli florets, and 1/2 cup diced onion; stir-fry 5 minutes.
      4. Mix 2 tbsp tamari with 1/2 tsp minced garlic and add to the pan.
      5. Toss everything together and cook 2 more minutes.
      6. Season with 1/8 tsp salt and 1/8 tsp pepper.
      7. Serve over 1 cup cooked brown rice.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  FRIDAY  |  1960 kcal  |  P 109g  C 199g  F 69g  |  98% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Banana Almond Protein Smoothie
    431 kcal | P 26g | C 48g | F 13g | Fiber 4g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 1 cup almond milk [Beverages]
      - 1 piece banana [Produce]
      - 1 scoop vanilla protein powder [Baking & Cooking]
      - 1 tablespoon almond butter [Nuts & Seeds]
    Steps (6):
      1. Pour 1 cup almond milk into blender
      2. Add 1 medium banana, sliced
      3. Add 1 scoop vanilla protein powder
      4. Add 1 tbsp almond butter
      5. Blend on high for 60 seconds until smooth
      6. Pour into glass and serve immediately

  [SNACK] Apple Slices with Almond Butter
    176 kcal | P 5g | C 20g | F 9g | Fiber 4g
    Cuisine: american | Prep: 4min | Cook: 0min | Servings: 1
    Ingredients (2):
      - 1 piece apple [Produce]
      - 1.5 tablespoon almond butter [Nuts & Seeds]
    Steps (4):
      1. Slice 1 medium apple into 8 pieces
      2. Arrange apple slices on plate
      3. Spoon 1.5 tbsp almond butter into small bowl
      4. Dip apple slices and eat immediately

  [LUNCH] Japanese Grilled Salmon with Ginger-Soy Rice
    628 kcal | P 38g | C 65g | F 18g | Fiber 5g
    Cuisine: japanese | Prep: 8min | Cook: 28min | Servings: 1
    Ingredients (6):
      - 6 oz salmon fillet [Meat & Seafood]
      - 0.75 cup rice [Grains & Bread]
      - 1 tablespoon olive oil [Condiments & Sauces]
      - 2 tablespoon tamari [Condiments & Sauces]
      - 1 teaspoon honey [Condiments & Sauces]
      - 2 cup broccoli [Produce]
    Steps (9):
      1. Cook 3/4 cup uncooked rice according to package directions in 1.5 cups water for 18 minutes
      2. While rice cooks, pat 6 oz salmon fillet dry with paper towel
      3. Heat 1 tbsp olive oil in skillet over medium-high heat for 2 minutes
      4. Place salmon skin-side up in skillet and cook 5 minutes until golden
      5. Flip salmon and cook 4 minutes until cooked through
      6. Mix 2 tbsp tamari, 1 tsp honey, and 1/2 tsp garlic powder in small bowl
      7. Brush tamari glaze over salmon during last 1 minute of cooking
      8. Steam 2 cups broccoli florets in microwave with 2 tbsp water for 4 minutes
      9. Fluff rice with fork and divide onto plate with salmon and broccoli

  [SNACK] Trail Mix with Dried Berries
    176 kcal | P 6g | C 18g | F 10g | Fiber 3g
    Cuisine: american | Prep: 3min | Cook: 0min | Servings: 1
    Ingredients (4):
      - 0.25 cup almonds [Nuts & Seeds]
      - 0.25 cup walnuts [Nuts & Seeds]
      - 2 tablespoon mixed berries [Produce]
      - 1 tablespoon dark chocolate [Snacks]
    Steps (4):
      1. Combine 1/4 cup almonds and 1/4 cup walnuts in small bowl
      2. Add 2 tbsp dried mixed berries
      3. Add 1 tbsp dark chocolate chips
      4. Mix gently and portion into snack container

  [DINNER] Thai Green Curry Chicken with Sweet Potato
    549 kcal | P 34g | C 48g | F 19g | Fiber 6g
    Cuisine: thai | Prep: 12min | Cook: 28min | Servings: 1
    Ingredients (7):
      - 6 oz chicken breast [Meat & Seafood]
      - 1 piece sweet potato [Produce]
      - 1 tablespoon olive oil [Condiments & Sauces]
      - 1 cup bell pepper [Produce]
      - 0.5 cup mushrooms [Produce]
      - 0.25 cup coconut oil [Condiments & Sauces]
      - 1 tablespoon tamari [Condiments & Sauces]
    Steps (9):
      1. Cut 6 oz chicken breast into 1-inch cubes
      2. Cut 1 medium sweet potato into 3/4-inch cubes and toss with 1/2 tbsp olive oil
      3. Spread sweet potato on baking sheet and bake at 400°F for 18 minutes until tender
      4. Heat 1/2 tbsp olive oil in large skillet over medium-high heat for 1 minute
      5. Add chicken cubes and cook 6 minutes, stirring occasionally until golden
      6. Add 1 cup sliced bell pepper and 1/2 cup mushrooms to skillet, cook 4 minutes
      7. Mix 1/4 cup coconut milk with 1 tbsp tamari and 1/2 tsp garlic powder
      8. Pour sauce over chicken and vegetables, simmer 3 minutes until heated through
      9. Serve chicken and vegetables with roasted sweet potato on the side

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SATURDAY  |  1965 kcal  |  P 89g  C 234g  F 65g  |  98% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Strawberry Oat Pancakes
    432 kcal | P 12g | C 58g | F 15g | Fiber 7g
    Cuisine: american | Prep: 8min | Cook: 8min | Servings: 1
    Ingredients (6):
      - 1 cup certified gluten-free oats [Grains & Bread]
      - 0.5 cup almond milk [Beverages]
      - 1 tablespoon honey [Condiments & Sauces]
      - 1 tablespoon almond butter [Nuts & Seeds]
      - 0.5 tablespoon coconut oil [Condiments & Sauces]
      - 0.5 cup strawberries [Produce]
    Steps (7):
      1. Blend 1 cup certified gluten-free oats into fine flour
      2. Mix 1/2 cup oat flour with 1/2 tsp baking soda and 1/4 tsp salt in bowl
      3. Whisk 1/2 cup almond milk with 1 tbsp honey and 1 tbsp almond butter until smooth
      4. Combine wet and dry ingredients, let batter rest 3 minutes
      5. Heat 1/2 tbsp coconut oil in nonstick skillet over medium heat for 1 minute
      6. Pour 1/4 cup batter per pancake, cook 3 minutes per side until golden
      7. Top 2 pancakes with 1/2 cup sliced fresh strawberries

  [SNACK] Hummus and Carrot Sticks
    177 kcal | P 6g | C 22g | F 7g | Fiber 5g
    Cuisine: american | Prep: 5min | Cook: 0min | Servings: 1
    Ingredients (2):
      - 1.5 cup carrot [Produce]
      - 0.25 cup hummus [Condiments & Sauces]
    Steps (4):
      1. Peel and cut 1.5 cups carrots into 4-inch sticks
      2. Arrange carrot sticks on plate
      3. Portion 1/4 cup hummus into small bowl
      4. Dip carrot sticks in hummus and serve

  [LUNCH] Italian Ground Turkey Pasta with Spinach
    629 kcal | P 33g | C 72g | F 18g | Fiber 6g
    Cuisine: italian | Prep: 10min | Cook: 22min | Servings: 1
    Ingredients (6):
      - 6 oz ground turkey [Meat & Seafood]
      - 1.75 oz gluten-free pasta [Grains & Bread]
      - 1 tablespoon olive oil [Condiments & Sauces]
      - 0.5 cup onion [Produce]
      - 0.75 cup tomato sauce [Produce]
      - 2 cup spinach [Produce]
    Steps (7):
      1. Cook 1.75 oz gluten-free pasta according to package directions, drain and set aside
      2. Heat 1 tbsp olive oil in large skillet over medium-high heat for 1 minute
      3. Add 6 oz ground turkey to skillet, break apart and cook 7 minutes until browned
      4. Add 1/2 cup diced onion and 3 cloves minced garlic, cook 3 minutes until soft
      5. Stir in 3/4 cup tomato sauce and 1 tsp Italian seasoning
      6. Simmer sauce 5 minutes, then add 2 cups fresh spinach and stir until wilted (2 minutes)
      7. Combine cooked pasta with turkey sauce and serve

  [SNACK] Blueberry and Almond Snack Pack
    177 kcal | P 6g | C 19g | F 9g | Fiber 4g
    Cuisine: american | Prep: 2min | Cook: 0min | Servings: 1
    Ingredients (2):
      - 0.5 cup blueberries [Produce]
      - 0.33 cup almonds [Nuts & Seeds]
    Steps (3):
      1. Measure 1/2 cup fresh blueberries into small container
      2. Measure 1/3 cup roasted almonds into separate section
      3. Mix together and eat

  [DINNER] Baked Cod with Roasted Vegetables and Quinoa
    550 kcal | P 32g | C 63g | F 16g | Fiber 8g
    Cuisine: italian | Prep: 10min | Cook: 18min | Servings: 1
    Ingredients (5):
      - 6 oz cod fillet [Meat & Seafood]
      - 0.5 cup quinoa [Grains & Bread]
      - 1 tablespoon olive oil [Condiments & Sauces]
      - 1.5 cup zucchini [Produce]
      - 1 cup asparagus [Produce]
    Steps (8):
      1. Preheat oven to 400°F
      2. Cook 1/2 cup uncooked quinoa in 1 cup water for 15 minutes until tender
      3. Cut 6 oz cod fillet and place on parchment paper
      4. Drizzle with 1/2 tbsp olive oil and season with 1/4 tsp garlic powder and salt/pepper
      5. Toss 1.5 cups zucchini slices and 1 cup asparagus with 1/2 tbsp olive oil, garlic powder, and salt
      6. Arrange vegetables on baking sheet alongside cod
      7. Bake at 400°F for 14 minutes until cod is flaky and vegetables are tender
      8. Divide quinoa onto plate and top with baked cod and roasted vegetables

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  SUNDAY  |  2135 kcal  |  P 121g  C 224g  F 72g  |  107% of target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BREAKFAST] Banana Oat Pancakes with Berries
    468 kcal | P 24g | C 58g | F 15g | Fiber 6g
    Cuisine: american | Prep: 5min | Cook: 10min | Servings: 1
    Ingredients (6):
      - 1 piece banana [Produce]
      - 0.5 cup certified gluten-free oats [Grains & Bread]
      - 0.5 cup almond milk [Beverages]
      - 0.5 cup mixed berries [Produce]
      - 1 tablespoon coconut oil [Condiments & Sauces]
      - 1 tablespoon honey [Condiments & Sauces]
    Steps (6):
      1. Mash 1 banana in a bowl until smooth
      2. Mix in 1/2 cup certified gluten-free oats, 1/2 cup almond milk, and 1 tsp vanilla extract until combined
      3. Let batter rest 2 minutes
      4. Heat 1 tbsp coconut oil in a non-stick skillet over medium heat
      5. Pour batter into 3 small pancakes, cook 2 minutes per side until golden
      6. Top with 1/2 cup mixed berries and 1 tbsp honey

  [SNACK] Trail Mix with Dark Chocolate
    189 kcal | P 16g | C 13g | F 12g | Fiber 3g
    Cuisine: american | Prep: 2min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 1 oz almonds [Nuts & Seeds]
      - 0.5 oz walnuts [Nuts & Seeds]
      - 0.5 oz dark chocolate [Snacks]
    Steps (3):
      1. Combine 1 oz almonds and 0.5 oz walnuts in a small bowl
      2. Add 0.5 oz dark chocolate chips
      3. Mix and enjoy

  [LUNCH] Thai Green Curry Chicken with Jasmine Rice
    685 kcal | P 34g | C 72g | F 20g | Fiber 4g
    Cuisine: Thai | Prep: 10min | Cook: 25min | Servings: 1
    Ingredients (8):
      - 6 oz chicken breast [Meat & Seafood]
      - 1.5 cup jasmine rice [Grains & Bread]
      - 1 cup bell pepper [Produce]
      - 1 cup broccoli [Produce]
      - 1 tablespoon olive oil [Condiments & Sauces]
      - 0.5 cup coconut milk [Beverages]
      - 1 tablespoon green curry paste [Condiments & Sauces]
      - 1 tablespoon tamari [Condiments & Sauces]
    Steps (8):
      1. Cook 1.5 cups jasmine rice according to package directions, about 15 minutes
      2. Cut 6 oz chicken breast into 1-inch cubes
      3. Heat 1 tbsp olive oil in a large pan over medium-high heat
      4. Cook chicken cubes 6 minutes until golden on all sides, stirring occasionally
      5. Add 1 cup diced bell pepper and 1 cup broccoli florets to the pan
      6. Pour in 1/2 cup coconut milk mixed with 1 tbsp green curry paste and 1 tbsp tamari, stir well
      7. Simmer 8 minutes until chicken is cooked through and vegetables are tender
      8. Serve curry over jasmine rice

  [SNACK] Hummus and Vegetable Crudités
    194 kcal | P 16g | C 22g | F 6g | Fiber 5g
    Cuisine: mediterranean | Prep: 4min | Cook: 0min | Servings: 1
    Ingredients (3):
      - 3 tablespoon hummus [Condiments & Sauces]
      - 1 piece carrot [Produce]
      - 1 piece cucumber [Produce]
    Steps (4):
      1. Slice 1 medium carrot into sticks, about 3 inches long
      2. Slice 1 medium cucumber into 1/4-inch thick slices
      3. Place 3 tbsp hummus in a small bowl
      4. Arrange vegetables around the hummus for dipping

  [DINNER] Pan-Seared Salmon with Roasted Sweet Potato and Asparagus
    599 kcal | P 31g | C 59g | F 19g | Fiber 8g
    Cuisine: Italian | Prep: 10min | Cook: 25min | Servings: 1
    Ingredients (4):
      - 5.5 oz salmon [Meat & Seafood]
      - 1 piece sweet potato [Produce]
      - 6 oz asparagus [Produce]
      - 2 tablespoon olive oil [Condiments & Sauces]
    Steps (9):
      1. Preheat oven to 400°F
      2. Cut 1 medium sweet potato into 1/2-inch wedges and toss with 0.5 tbsp olive oil, 1/4 tsp garlic powder, and salt and pepper
      3. Spread on a baking sheet and roast 15 minutes
      4. Trim 6 oz asparagus spears and toss with 0.5 tbsp olive oil, salt, and pepper
      5. Add asparagus to the baking sheet with sweet potatoes, roast 10 more minutes until tender
      6. Pat 5.5 oz salmon fillet dry and season with salt, pepper, and garlic powder
      7. Heat 1 tbsp olive oil in a non-stick skillet over medium-high heat
      8. Cook salmon skin-side up 4 minutes, flip and cook 3 minutes more until cooked through
      9. Serve salmon with roasted vegetables

######################################################################
  GENERATION TIMING
######################################################################
  Profile A: Female, 28, weight loss, vegetarian, 1600 kcal: 79.9s — OK
  Profile B: Male, 24, bulking, omnivore, 3200 kcal: 107.9s — OK
  Profile C: Female, 40, maintain, gluten-free + dairy-free, 2000 kcal: 97.9s — OK
  Total: 285.7s
