//
//  MealPrepAIApp.swift
//  MealPrepAI
//
//  Created by Sebastián Kučera on 17.01.2026.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAppCheck

// MARK: - Notification Names
extension Notification.Name {
    static let accountDeleted = Notification.Name("accountDeleted")
}

// MARK: - App Attest Provider Factory
/// Custom factory for App Attest provider (production builds)
class CustomAppAttestProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> (any AppCheckProvider)? {
        return AppAttestProvider(app: app)
    }
}

// MARK: - App Delegate
/// Handles app lifecycle events
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Firebase is configured in MealPrepAIApp.init() before this runs
        print("🔥 [AppDelegate] didFinishLaunchingWithOptions")
        return true
    }
}

// Create ModelContainer with CloudKit sync for user data
let sharedModelContainer: ModelContainer = {
    let schema = Schema([
        UserProfile.self,
        MealPlan.self,
        Day.self,
        Meal.self,
        Recipe.self,
        RecipeIngredient.self,
        Ingredient.self,
        GroceryList.self,
        GroceryItem.self
    ])

    // Enable CloudKit sync with the iCloud container
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .private("iCloud.com.mealprepai.MealPrepAI")
    )

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()

@main
struct MealPrepAIApp: App {
    // Firebase App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // MARK: - State Managers
    @State private var authManager = AuthenticationManager()
    @State private var syncManager = CloudKitSyncManager()
    @State private var healthKitManager = HealthKitManager()
    @State private var notificationManager = NotificationManager()

    // Firebase Recipe Services - initialized after Firebase is configured
    @State private var firebaseRecipeService: FirebaseRecipeService

    init() {
        // Configure App Check BEFORE Firebase.configure()
        // Uses App Attest in production, Debug provider in development
        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        #else
        let providerFactory = CustomAppAttestProviderFactory()
        #endif
        AppCheck.setAppCheckProviderFactory(providerFactory)
        print("🔒 [App] App Check configured with \(type(of: providerFactory))")

        // Configure Firebase FIRST, before any Firebase services are created
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("🔥 [App] Firebase configured in init")
        }

        // Now safe to create Firebase services
        _firebaseRecipeService = State(initialValue: FirebaseRecipeService())
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch authManager.authState {
                case .unknown:
                    SplashView()

                case .unauthenticated, .guest, .authenticated:
                    // Show RootView for all states - it handles onboarding vs main content
                    RootView()
                        .environment(authManager)
                        .environment(syncManager)
                        .environment(healthKitManager)
                        .environment(notificationManager)
                        .environment(firebaseRecipeService)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authManager.authState)
        }
        .modelContainer(sharedModelContainer)
    }
}

/* DISABLED FOR TESTING - Original body:
            Group {
                switch authManager.authState {
                case .unknown:
                    SplashView()
                case .unauthenticated:
                    AuthenticationView()
                        .environment(authManager)
                case .guest, .authenticated:
                    RootView()
                        .environment(authManager)
                        .environment(syncManager)
                        .environment(healthKitManager)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authManager.authState)
*/

// MARK: - Splash View
struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient.mintBackgroundGradient
                .ignoresSafeArea()

            VStack(spacing: Design.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.purpleButtonGradient)
                        .frame(width: 100, height: 100)

                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }

                Text("MealPrepAI")
                    .font(Design.Typography.title)
                    .foregroundStyle(Color.textPrimary)

                ProgressView()
                    .tint(Color.accentPurple)
            }
        }
    }
}

// Root view - checks onboarding status and shows appropriate view
struct RootView: View {
    @Environment(AuthenticationManager.self) var authManager
    @Environment(CloudKitSyncManager.self) var syncManager
    @Environment(HealthKitManager.self) var healthKitManager
    @Query private var userProfiles: [UserProfile]
    @State private var showOnboarding = false
    @State private var showLaunchScreen = true
    @State private var showSignInSheet = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    private var hasCompletedOnboarding: Bool {
        userProfiles.first?.hasCompletedOnboarding ?? false
    }

    init() {
        // Configure Tab Bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Configure Navigation Bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(authManager)
                    .environment(syncManager)
                    .environment(healthKitManager)
            } else if showLaunchScreen {
                // Show the new launch screen first
                LaunchScreenView(
                    onGetStarted: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showLaunchScreen = false
                            showOnboarding = true
                        }
                    },
                    onSignIn: {
                        // Show sign-in sheet for existing users
                        showSignInSheet = true
                    }
                )
                .fullScreenCover(isPresented: $showSignInSheet) {
                    AuthenticationView()
                        .environment(authManager)
                }
            } else if showOnboarding {
                // Show new onboarding flow
                NewOnboardingView(
                    onComplete: {
                        // View will automatically update when profile is saved
                    },
                    onLogin: {
                        // Go back to launch screen or auth
                        withAnimation {
                            showLaunchScreen = true
                            showOnboarding = false
                        }
                    }
                )
                .environment(authManager)
            } else {
                // Fallback to legacy onboarding
                OnboardingView(onComplete: {
                    // View will automatically update when profile is saved
                })
                .environment(authManager)
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .accountDeleted)) { _ in
            // Reset to launch screen when account is deleted
            withAnimation(.easeInOut(duration: 0.3)) {
                showLaunchScreen = true
                showOnboarding = false
            }
        }
    }
}
