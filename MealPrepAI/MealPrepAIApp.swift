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
import FirebaseAnalytics
import SuperwallKit

// MARK: - App Configuration
enum AppConfig {
    enum Superwall {
        static let apiKey = "pk_Sk5q5XhpVeMrBXV1EJ1X_"
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

/// Tracks whether ModelContainer fell back to in-memory storage
var didFallBackToInMemoryStore = false

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
        didFallBackToInMemoryStore = true
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
    @State private var subscriptionManager: SubscriptionManager
    @State private var networkMonitor = NetworkMonitor()
    @State private var streakManager = StreakManager()
    @State private var showDataStorageAlert = didFallBackToInMemoryStore

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

        // Configure Superwall with PurchaseController for subscription-aware paywall gating
        let subManager = SubscriptionManager()
        _subscriptionManager = State(initialValue: subManager)
        let purchaseController = SuperwallPurchaseController(subscriptionManager: subManager)
        Superwall.configure(apiKey: AppConfig.Superwall.apiKey, purchaseController: purchaseController)

        // Configure analytics (Firebase Analytics SDK already linked)
        AnalyticsService.shared.configure()

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

    @MainActor
    private func refreshStreakOnLaunch() {
        let context = sharedModelContainer.mainContext
        let planDescriptor = FetchDescriptor<MealPlan>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let plan = try? context.fetch(planDescriptor).first else { return }
        streakManager.refreshStreak(days: plan.sortedDays)
    }

    @Environment(\.scenePhase) private var scenePhase

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
                        .environment(streakManager)
                        .task {
                            await rescheduleNotificationsOnLaunch()
                        }
                        .task {
                            refreshStreakOnLaunch()
                        }
                        .task {
                            // Set user properties from profile for analytics segmentation
                            let context = sharedModelContainer.mainContext
                            let descriptor = FetchDescriptor<UserProfile>()
                            if let profile = try? context.fetch(descriptor).first {
                                AnalyticsService.shared.setUserProperties(from: profile)
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authManager.authState)
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    AnalyticsService.shared.trackSessionStart()
                case .background:
                    AnalyticsService.shared.trackSessionEnd()
                default:
                    break
                }
            }
            .alert("Data Storage Issue", isPresented: $showDataStorageAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your data couldn't be saved to persistent storage. Any data created this session may be lost when you close the app. Try restarting the app or freeing up device storage.")
            }
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

    private static var appearanceConfigured = false

    private var hasCompletedOnboarding: Bool {
        userProfiles.first?.hasCompletedOnboarding ?? false
    }

    init() {
        guard !Self.appearanceConfigured else { return }
        Self.appearanceConfigured = true

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
