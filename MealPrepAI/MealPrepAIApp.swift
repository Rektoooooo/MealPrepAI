//
//  MealPrepAIApp.swift
//  MealPrepAI
//
//  Created by Sebastián Kučera on 17.01.2026.
//

import SwiftUI
import SwiftData

// Create ModelContainer without CloudKit sync (CloudKit requires all attributes optional)
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

    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: .none  // Disable CloudKit - enable later when models are CloudKit-compatible
    )

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()

@main
struct MealPrepAIApp: App {
    @State private var authManager = AuthenticationManager()
    @State private var syncManager = CloudKitSyncManager()
    @State private var healthKitManager = HealthKitManager()
    @State private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
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
                        .environment(notificationManager)
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
            } else {
                OnboardingView(onComplete: {
                    // View will automatically update when profile is saved
                })
                .environment(authManager)
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }
}
