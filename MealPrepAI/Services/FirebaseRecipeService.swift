import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firebase Recipe Service
/// Service for fetching recipes from Firebase Firestore
/// Uses Firebase SDK to query the recipes collection populated by Cloud Functions
@MainActor
@Observable
final class FirebaseRecipeService {
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    /// Loading state
    var isLoading = false

    /// Error message if fetch failed
    var errorMessage: String?

    /// Last successful fetch time
    var lastFetchTime: Date?

    /// Whether user is authenticated with Firebase
    var isAuthenticated: Bool { Auth.auth().currentUser != nil }

    // MARK: - Constants
    private let recipesCollection = "recipes" // All API recipes (Spoonacular)
    private let defaultLimit = 50
    private let searchLimit = 50
    private let pageSize = 50

    /// Whether Firebase is properly configured
    var isFirebaseConfigured: Bool { true }

    /// Last document for pagination cursor
    private var lastDocument: DocumentSnapshot?

    /// Whether there are more recipes to load
    var hasMoreRecipes = true

    /// Whether pagination has been initialized (initial fetch was done)
    var isPaginationInitialized: Bool { lastDocument != nil }

    /// Total recipes available in Firebase (cached)
    var totalRecipesCount: Int = 0

    // MARK: - Initialization
    init() {
        print("🔥 [FirebaseRecipeService] Initializing...")
        // Sign in anonymously on init
        Task {
            await ensureAuthenticated()
        }
    }

    // Note: Cleanup is handled by stopListening() which should be called before deallocation
    // deinit cannot access @MainActor-isolated properties

    // MARK: - Authentication

    /// Ensure user is signed in anonymously to Firebase
    private func ensureAuthenticated() async {
        if let user = Auth.auth().currentUser {
            print("🔐 [Firebase Auth] Already signed in as: \(user.uid)")
            return
        }

        print("🔐 [Firebase Auth] No user found, signing in anonymously...")
        do {
            let result = try await Auth.auth().signInAnonymously()
            print("✅ [Firebase Auth] Signed in anonymously as: \(result.user.uid)")
        } catch {
            print("❌ [Firebase Auth] Sign-in failed: \(error.localizedDescription)")
            errorMessage = "Authentication failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Fetch Methods

    /// Fetch all recipes from the recipes collection
    func fetchRecipes(limit: Int = 100) async throws -> [FirebaseRecipe] {
        print("📥 [Firestore] Fetching recipes (limit: \(limit))...")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Ensure authenticated before fetching
        await ensureAuthenticated()

        let recipes = try await fetchRecipesFromCollection(recipesCollection, limit: limit)
        print("✅ [Firestore] Fetched \(recipes.count) recipes")
        lastFetchTime = Date()

        return recipes
    }

    /// Helper: Fetch recipes from a specific collection
    private func fetchRecipesFromCollection(_ collection: String, limit: Int) async throws -> [FirebaseRecipe] {
        print("📥 [Firestore] Querying collection: \(collection)")
        let snapshot = try await db.collection(collection)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        print("📥 [Firestore] Got \(snapshot.documents.count) documents from \(collection)")

        var successCount = 0
        var failCount = 0

        let recipes = snapshot.documents.compactMap { document -> FirebaseRecipe? in
            do {
                var recipe = try document.data(as: FirebaseRecipe.self)
                recipe.id = document.documentID
                successCount += 1
                return recipe
            } catch {
                failCount += 1
                print("⚠️ [Firestore] Error decoding recipe \(document.documentID): \(error)")
                return nil
            }
        }

        print("✅ [Firestore] Decoded \(successCount) recipes from \(collection), \(failCount) failed")
        return recipes
    }

    /// Fetch recipes filtered by cuisine type
    func fetchRecipes(cuisine: String) async throws -> [FirebaseRecipe] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        await ensureAuthenticated()

        let snapshot = try await db.collection(recipesCollection)
            .whereField("cuisineType", isEqualTo: cuisine.lowercased())
            .limit(to: searchLimit)
            .getDocuments()

        lastFetchTime = Date()

        return snapshot.documents.compactMap { document in
            do {
                var recipe = try document.data(as: FirebaseRecipe.self)
                recipe.id = document.documentID
                return recipe
            } catch {
                print("Error decoding recipe: \(error)")
                return nil
            }
        }
    }

    /// Fetch recipes filtered by meal type
    func fetchRecipes(mealType: String) async throws -> [FirebaseRecipe] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let snapshot = try await db.collection(recipesCollection)
            .whereField("mealType", isEqualTo: mealType.lowercased())
            .limit(to: searchLimit)
            .getDocuments()

        lastFetchTime = Date()

        return snapshot.documents.compactMap { document in
            do {
                var recipe = try document.data(as: FirebaseRecipe.self)
                recipe.id = document.documentID
                return recipe
            } catch {
                print("Error decoding recipe: \(error)")
                return nil
            }
        }
    }

    /// Fetch recipes that match a dietary restriction
    func fetchRecipes(diet: String) async throws -> [FirebaseRecipe] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let snapshot = try await db.collection(recipesCollection)
            .whereField("diets", arrayContains: diet.lowercased())
            .limit(to: searchLimit)
            .getDocuments()

        lastFetchTime = Date()

        return snapshot.documents.compactMap { document in
            do {
                var recipe = try document.data(as: FirebaseRecipe.self)
                recipe.id = document.documentID
                return recipe
            } catch {
                print("Error decoding recipe: \(error)")
                return nil
            }
        }
    }

    /// Fetch recipes with multiple filters
    func fetchRecipes(
        cuisine: String? = nil,
        mealType: String? = nil,
        maxTime: Int? = nil
    ) async throws -> [FirebaseRecipe] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var query: Query = db.collection(recipesCollection)

        if let cuisine = cuisine {
            query = query.whereField("cuisineType", isEqualTo: cuisine.lowercased())
        }

        if let mealType = mealType {
            query = query.whereField("mealType", isEqualTo: mealType.lowercased())
        }

        if let maxTime = maxTime {
            query = query.whereField("readyInMinutes", isLessThanOrEqualTo: maxTime)
        }

        query = query.limit(to: searchLimit)

        let snapshot = try await query.getDocuments()
        lastFetchTime = Date()

        return snapshot.documents.compactMap { document in
            do {
                var recipe = try document.data(as: FirebaseRecipe.self)
                recipe.id = document.documentID
                return recipe
            } catch {
                print("Error decoding recipe: \(error)")
                return nil
            }
        }
    }

    /// Fetch a single recipe by its Firebase document ID
    func fetchRecipe(byId id: String) async throws -> FirebaseRecipe? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let document = try await db.collection(recipesCollection).document(id).getDocument()

        guard document.exists else { return nil }

        var recipe = try document.data(as: FirebaseRecipe.self)
        recipe.id = document.documentID
        return recipe
    }

    /// Search recipes by title in Firebase
    /// Firestore doesn't support full-text search, so we fetch a limited set and filter client-side
    /// For better performance, we use multiple search strategies
    func searchRecipes(query: String) async throws -> [FirebaseRecipe] {
        print("🔍 [Firestore] Searching for: '\(query)'")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        await ensureAuthenticated()

        let lowercasedQuery = query.lowercased()
        let capitalizedQuery = query.capitalized
        var allResults: [String: FirebaseRecipe] = [:] // Use dict to dedupe by ID

        // Strategy 1: Try prefix search on title (most efficient)
        // Firestore supports range queries for prefix matching
        let prefixEnd = capitalizedQuery + "\u{f8ff}" // Unicode character after all others
        let prefixSnapshot = try await db.collection(recipesCollection)
            .order(by: "title")
            .start(at: [capitalizedQuery])
            .end(at: [prefixEnd])
            .limit(to: searchLimit)
            .getDocuments()

        for document in prefixSnapshot.documents {
            if let recipe = try? document.data(as: FirebaseRecipe.self) {
                var mutableRecipe = recipe
                mutableRecipe.id = document.documentID
                allResults[document.documentID] = mutableRecipe
            }
        }

        print("🔍 [Firestore] Prefix search found \(prefixSnapshot.documents.count) results")

        // Strategy 2: If prefix search didn't find enough, do a broader search with limit
        if allResults.count < 20 {
            let broadSnapshot = try await db.collection(recipesCollection)
                .order(by: "createdAt", descending: true)
                .limit(to: 200) // Limit to prevent fetching entire database
                .getDocuments()

            for document in broadSnapshot.documents {
                // Skip if already found
                guard allResults[document.documentID] == nil else { continue }

                if var recipe = try? document.data(as: FirebaseRecipe.self) {
                    recipe.id = document.documentID

                    // Filter by title or ingredient name (case-insensitive)
                    let titleMatches = recipe.title.lowercased().contains(lowercasedQuery)
                    let ingredientMatches = recipe.ingredients.contains {
                        $0.name.lowercased().contains(lowercasedQuery)
                    }

                    if titleMatches || ingredientMatches {
                        allResults[document.documentID] = recipe
                    }
                }
            }

            print("🔍 [Firestore] Broad search added \(allResults.count - prefixSnapshot.documents.count) more results")
        }

        let results = Array(allResults.values)
        print("🔍 [Firestore] Total: \(results.count) results for '\(query)'")
        return results
    }

    // MARK: - Pagination Methods

    /// Reset pagination state
    func resetPagination() {
        lastDocument = nil
        hasMoreRecipes = true
        print("🔄 [Firestore] Pagination reset")
    }

    /// Fetch initial page of recipes from the recipes collection
    func fetchInitialRecipes() async throws -> [FirebaseRecipe] {
        print("📥 [Firestore] Fetching initial page...")
        resetPagination()

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        await ensureAuthenticated()

        // Get total count
        let countResult = try await db.collection(recipesCollection).count.getAggregation(source: .server)
        totalRecipesCount = Int(truncating: countResult.count)
        print("📊 [Firestore] Total recipes available: \(totalRecipesCount)")

        // Fetch initial page
        let snapshot = try await db.collection(recipesCollection)
            .order(by: "createdAt", descending: true)
            .limit(to: pageSize)
            .getDocuments()

        // Store last document for pagination
        lastDocument = snapshot.documents.last
        hasMoreRecipes = snapshot.documents.count >= pageSize

        lastFetchTime = Date()

        // Parse recipes
        let recipes = snapshot.documents.compactMap { document -> FirebaseRecipe? in
            do {
                var recipe = try document.data(as: FirebaseRecipe.self)
                recipe.id = document.documentID
                return recipe
            } catch {
                print("⚠️ [Firestore] Error decoding recipe \(document.documentID): \(error)")
                return nil
            }
        }

        print("✅ [Firestore] Fetched \(recipes.count) recipes (hasMore: \(hasMoreRecipes))")
        return recipes
    }

    /// Fetch next page of recipes
    func fetchMoreRecipes() async throws -> [FirebaseRecipe] {
        guard hasMoreRecipes, let lastDoc = lastDocument else {
            print("📥 [Firestore] No more recipes to fetch")
            return []
        }

        print("📥 [Firestore] Fetching next page...")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        await ensureAuthenticated()

        let snapshot = try await db.collection(recipesCollection)
            .order(by: "createdAt", descending: true)
            .start(afterDocument: lastDoc)
            .limit(to: pageSize)
            .getDocuments()

        // Update pagination state
        lastDocument = snapshot.documents.last
        hasMoreRecipes = snapshot.documents.count == pageSize

        let recipes = snapshot.documents.compactMap { document -> FirebaseRecipe? in
            do {
                var recipe = try document.data(as: FirebaseRecipe.self)
                recipe.id = document.documentID
                return recipe
            } catch {
                return nil
            }
        }

        print("✅ [Firestore] Fetched \(recipes.count) more recipes (hasMore: \(hasMoreRecipes))")
        return recipes
    }

    // MARK: - Real-time Listening

    /// Start listening for real-time updates to recipes
    func listenForUpdates(onUpdate: @escaping ([FirebaseRecipe]) -> Void) {
        listener = db.collection(recipesCollection)
            .order(by: "createdAt", descending: true)
            .limit(to: defaultLimit)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else { return }

                let recipes = documents.compactMap { document -> FirebaseRecipe? in
                    do {
                        var recipe = try document.data(as: FirebaseRecipe.self)
                        recipe.id = document.documentID
                        return recipe
                    } catch {
                        return nil
                    }
                }

                onUpdate(recipes)
            }
    }

    /// Stop listening for real-time updates
    func stopListening() {
        listener?.remove()
        listener = nil
    }

    // MARK: - Statistics

    /// Get total recipe count in Firestore
    func getRecipeCount() async throws -> Int {
        let snapshot = try await db.collection(recipesCollection).count.getAggregation(source: .server)
        return Int(truncating: snapshot.count)
    }

    /// Get count of recipes by cuisine type
    func getRecipeCount(cuisine: String) async throws -> Int {
        let snapshot = try await db.collection(recipesCollection)
            .whereField("cuisineType", isEqualTo: cuisine.lowercased())
            .count
            .getAggregation(source: .server)
        return Int(truncating: snapshot.count)
    }
}

// MARK: - Error Handling
extension FirebaseRecipeService {
    enum ServiceError: LocalizedError {
        case notConfigured
        case fetchFailed(String)
        case documentNotFound

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Firebase is not configured. Please check your GoogleService-Info.plist."
            case .fetchFailed(let message):
                return "Failed to fetch recipes: \(message)"
            case .documentNotFound:
                return "Recipe not found."
            }
        }
    }
}
