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
import SuperwallKit

// MARK: - App Configuration
enum AppConfig {
    enum Superwall {
        #if DEBUG
        static let apiKey = "pk_Sk5q5XhpVeMrBXV1EJ1X_"
        #else
        static let apiKey = "pk_Sk5q5XhpVeMrBXV1EJ1X_"
        #endif
    }
}

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
        #if DEBUG
        print("🔥 [AppDelegate] didFinishLaunchingWithOptions")
        #endif
        return true
    }
}

// Create ModelContainer with CloudKit sync and schema versioning
let sharedModelContainer: ModelContainer = {
    let schema = Schema(versionedSchema: SchemaV1.self)

    // Local-only storage (CloudKit requires all relationships to be optional;
    // enable CloudKit later once model relationships are updated)
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .none
    )

    do {
        return try ModelContainer(
            for: schema,
            migrationPlan: MealPrepAIMigrationPlan.self,
            configurations: [modelConfiguration]
        )
    } catch {
        #if DEBUG
        print("ModelContainer creation failed: \(error). Falling back to in-memory store.")
        #endif
        // Fallback to in-memory store so the app can still launch
        let fallbackConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [fallbackConfig])
        } catch {
            fatalError("Could not create even in-memory ModelContainer: \(error)")
        }
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
    @State private var subscriptionManager = SubscriptionManager()
    @State private var networkMonitor = NetworkMonitor()

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
        #if DEBUG
        print("🔒 [App] App Check configured with \(type(of: providerFactory))")
        #endif

        // Configure Firebase FIRST, before any Firebase services are created
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            #if DEBUG
            print("🔥 [App] Firebase configured in init")
            #endif
        }

        // Configure persistent URL cache for image downloads (50 MB memory, 200 MB disk)
        URLCache.shared = URLCache(
            memoryCapacity: 50_000_000,
            diskCapacity: 200_000_000
        )

        // Configure Superwall for analytics tracking
        Superwall.configure(apiKey: AppConfig.Superwall.apiKey)

        // Now safe to create Firebase services
        _firebaseRecipeService = State(initialValue: FirebaseRecipeService())
    }

    @MainActor
    private func rescheduleNotificationsOnLaunch() async {
        let context = sharedModelContainer.mainContext
        let planDescriptor = FetchDescriptor<MealPlan>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let profileDescriptor = FetchDescriptor<UserProfile>()

        let activePlan = try? context.fetch(planDescriptor).first
        let profile = try? context.fetch(profileDescriptor).first

        await notificationManager.rescheduleAllNotifications(
            activePlan: activePlan,
            isSubscribed: subscriptionManager.isSubscribed,
            trialStartDate: profile?.createdAt
        )
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
                        .environment(subscriptionManager)
                        .environment(networkMonitor)
                        .task {
                            await rescheduleNotificationsOnLaunch()
                        }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authManager.authState)
        }
        .modelContainer(sharedModelContainer)
    }
}


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
                        .font(Design.Typography.iconMedium)
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
            } else {
                // Show onboarding flow
                NewOnboardingView(
                    onComplete: {
                        // View will automatically update when profile is saved
                    },
                    onLogin: {
                        // Go back to launch screen or auth
                        withAnimation {
                            showLaunchScreen = true
                        }
                    }
                )
                .environment(authManager)
                .environment(syncManager)
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .accountDeleted)) { _ in
            // Reset to launch screen when account is deleted
            withAnimation(.easeInOut(duration: 0.3)) {
                showLaunchScreen = true
            }
        }
    }
}
