import SwiftUI
import SwiftData
import StoreKit
import AuthenticationServices

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthenticationManager.self) var authManager
    @Environment(CloudKitSyncManager.self) var syncManager
    @Environment(HealthKitManager.self) var healthKitManager
    @Query private var userProfiles: [UserProfile]
    @Query private var recipes: [Recipe]

    @State private var showingEditProfile = false
    @State private var showingSignOutAlert = false
    @State private var showingOnboardingPreview = false
    @State private var animateContent = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric

    private var profile: UserProfile? {
        userProfiles.first
    }

    private var favoriteRecipes: [Recipe] {
        recipes.filter { $0.isFavorite }
    }

    private var mealsLogged: Int {
        recipes.reduce(0) { $0 + $1.timesUsed }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Design.Spacing.lg) {
                    // Profile Header Card
                    profileHeader
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Stats Card
                    statsCard
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Goals Section
                    goalsSection
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Preferences Section
                    preferencesSection
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)

                    // Settings Section
                    settingsSection
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                }
                .padding(.horizontal, Design.Spacing.md)
                .padding(.bottom, Design.Spacing.xxl)
            }
            .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(Design.Typography.headline)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingEditProfile = true }) {
                        Text("Edit")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentPurple)
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                if let profile = profile {
                    EditProfileSheet(profile: profile)
                }
            }
            .fullScreenCover(isPresented: $showingOnboardingPreview) {
                OnboardingPreviewWrapper {
                    showingOnboardingPreview = false
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    animateContent = true
                }
                // Check CloudKit availability for iCloud sync toggle
                syncManager.checkCloudKitAvailability()
            }
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: Design.Spacing.md) {
            // Avatar with gradient ring
            ZStack {
                Circle()
                    .stroke(LinearGradient.purpleButtonGradient, lineWidth: 4)
                    .frame(width: 94, height: 94)

                Circle()
                    .fill(LinearGradient.purpleButtonGradient)
                    .frame(width: 84, height: 84)

                Text(profile?.name.prefix(2).uppercased() ?? "??")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            VStack(spacing: Design.Spacing.xxs) {
                Text(profile?.name ?? "Guest")
                    .font(Design.Typography.title)
                    .foregroundStyle(Color.textPrimary)

                if let createdAt = profile?.createdAt {
                    Text("Member since \(createdAt.formatted(.dateTime.month(.wide).year()))")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Design.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(Color.cardBackground)
                .shadow(
                    color: Design.Shadow.card.color,
                    radius: Design.Shadow.card.radius,
                    y: Design.Shadow.card.y
                )
        )
    }

    // MARK: - Stats Card
    private var statsCard: some View {
        HStack(spacing: 0) {
            let daysSinceCreation = profile.map { Calendar.current.dateComponents([.day], from: $0.createdAt, to: Date()).day ?? 0 } ?? 0
            statItem(value: "\(daysSinceCreation)", label: "Days Active", icon: "flame.fill", color: Color.accentYellow)
            Divider().frame(height: 40)
            statItem(value: "\(mealsLogged)", label: "Meals Logged", icon: "fork.knife", color: Color.mintVibrant)
            Divider().frame(height: 40)
            statItem(value: "\(favoriteRecipes.count)", label: "Favorites", icon: "heart.fill", color: Color(hex: "FF6B9D"))
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(Color.cardBackground)
                .shadow(
                    color: Design.Shadow.card.color,
                    radius: Design.Shadow.card.radius,
                    y: Design.Shadow.card.y
                )
        )
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: Design.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Daily Goals", icon: "target", iconColor: Color.accentPurple, showSeeAll: true)

            VStack(spacing: Design.Spacing.sm) {
                goalRow(icon: "flame.fill", color: Color(hex: "FF6B6B"), label: "Calories", value: "\(profile?.dailyCalorieTarget ?? 2000) cal")
                goalRow(icon: "p.circle.fill", color: Color.accentPurple, label: "Protein", value: "\(profile?.proteinGrams ?? 150)g")
                goalRow(icon: "c.circle.fill", color: Color.accentYellow, label: "Carbs", value: "\(profile?.carbsGrams ?? 200)g")
                goalRow(icon: "f.circle.fill", color: Color.mintVibrant, label: "Fat", value: "\(profile?.fatGrams ?? 65)g")
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )
        }
    }

    private func goalRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }

            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
        }
    }

    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Preferences", icon: "slider.horizontal.3", iconColor: Color.textSecondary)

            VStack(spacing: Design.Spacing.sm) {
                let dietValues = profile?.dietaryRestrictions.map { $0.rawValue } ?? []
                preferenceRow(label: "Diet", values: dietValues.isEmpty ? ["None"] : dietValues)

                let allergyValues = profile?.allergies.map { $0.rawValue } ?? []
                preferenceRow(label: "Allergies", values: allergyValues.isEmpty ? ["None"] : allergyValues)

                let cuisineValues = profile?.preferredCuisines.map { $0.rawValue } ?? []
                preferenceRow(label: "Cuisines", values: cuisineValues.isEmpty ? ["Any"] : cuisineValues)

                preferenceRow(label: "Skill", values: [profile?.cookingSkill.rawValue ?? "Intermediate"])
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )
        }
    }

    private func preferenceRow(label: String, values: [String]) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 80, alignment: .leading)

            Spacer()

            FlowLayout(spacing: 6) {
                ForEach(values, id: \.self) { value in
                    Text(value)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentPurple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.accentPurple.opacity(0.12))
                        )
                }
            }
        }
    }

    // MARK: - Account Section
    private func makeAccountSection(syncManager: CloudKitSyncManager) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Account", icon: "person.circle.fill", iconColor: Color.accentPurple)

            VStack(spacing: Design.Spacing.sm) {
                // Account Status Row
                HStack(spacing: Design.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(authManager.hasAppleID ? Color.mintVibrant.opacity(0.15) : Color.accentYellow.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: authManager.hasAppleID ? "checkmark.seal.fill" : "person.fill.questionmark")
                            .font(.system(size: 16))
                            .foregroundStyle(authManager.hasAppleID ? Color.mintVibrant : Color.accentYellow)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(authManager.hasAppleID ? "Signed in with Apple" : "Guest Account")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textPrimary)

                        Text(authManager.hasAppleID ? "Your data syncs across devices" : "Sign in to back up your data")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()
                }

                Divider()
                    .padding(.vertical, Design.Spacing.xxs)

                // iCloud Sync Toggle (only for authenticated users)
                if authManager.hasAppleID {
                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(syncManager.isSyncEnabled ? Color.mintVibrant.opacity(0.15) : Color.accentPurple.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: syncManager.isSyncEnabled ? "checkmark.icloud.fill" : "icloud")
                                .font(.system(size: 16))
                                .foregroundStyle(syncManager.isSyncEnabled ? Color.mintVibrant : Color.accentPurple)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Sync")
                                .font(.subheadline)
                                .foregroundStyle(Color.textPrimary)

                            Text(syncManager.isSyncEnabled ? "Connected" : syncManager.availabilityMessage)
                                .font(.caption)
                                .foregroundStyle(syncManager.isSyncEnabled ? Color.mintVibrant : Color.textSecondary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { syncManager.isSyncEnabled },
                            set: { newValue in
                                if newValue {
                                    syncManager.enableSync(for: authManager.currentUserID ?? "")
                                } else {
                                    syncManager.disableSync()
                                }
                            }
                        ))
                            .labelsHidden()
                            .tint(Color.accentPurple)
                            .disabled(!syncManager.canEnableSync)
                    }

                    // Show last sync time when sync is enabled
                    if syncManager.isSyncEnabled {
                        Divider()
                            .padding(.vertical, Design.Spacing.xxs)

                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)

                            Text(syncManager.lastSyncDescription ?? "Syncing...")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)

                            Spacer()
                        }
                    }

                    Divider()
                        .padding(.vertical, Design.Spacing.xxs)
                }

                // Sign In / Sign Out Button
                if authManager.hasAppleID {
                    // Sign Out Button
                    Button(action: { showingSignOutAlert = true }) {
                        HStack(spacing: Design.Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "FF6B6B").opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color(hex: "FF6B6B"))
                            }

                            Text("Sign Out")
                                .font(.subheadline)
                                .foregroundStyle(Color(hex: "FF6B6B"))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.textSecondary.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    // Sign In with Apple Button
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    }, onCompletion: handleSignInResult)
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 44)
                    .cornerRadius(8)
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                handleSignOut()
            }
        } message: {
            Text("Signing out will delete all local data. You can sign back in to restore from iCloud.")
        }
    }

    // MARK: - Health Section
    private func makeHealthSection() -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Health", icon: "heart.fill", iconColor: .pink)

            VStack(spacing: Design.Spacing.sm) {
                // HealthKit availability check
                if !healthKitManager.isHealthKitAvailable {
                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.textSecondary.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("HealthKit Not Available")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textPrimary)

                            Text("Health data sync is not available on this device")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()
                    }
                } else {
                    // Enable HealthKit Toggle
                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.pink.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.pink)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync with Apple Health")
                                .font(.subheadline)
                                .foregroundStyle(Color.textPrimary)

                            Text(healthKitManager.isAuthorized ? "Connected" : "Not connected")
                                .font(.caption)
                                .foregroundStyle(healthKitManager.isAuthorized ? Color.mintVibrant : Color.textSecondary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { profile?.healthKitEnabled ?? false },
                            set: { newValue in
                                profile?.healthKitEnabled = newValue
                                if newValue && !healthKitManager.isAuthorized {
                                    Task {
                                        try? await healthKitManager.requestAuthorization()
                                    }
                                }
                            }
                        ))
                        .labelsHidden()
                        .tint(.pink)
                    }

                    // Show additional options only when enabled and authorized
                    if profile?.healthKitEnabled == true && healthKitManager.isAuthorized {
                        Divider()
                            .padding(.vertical, Design.Spacing.xxs)

                        // Log Nutrition Toggle
                        HStack(spacing: Design.Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentYellow.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "fork.knife")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.accentYellow)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Log Nutrition")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textPrimary)

                                Text("Save calories & macros when meals eaten")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { profile?.syncNutritionToHealth ?? true },
                                set: { profile?.syncNutritionToHealth = $0 }
                            ))
                            .labelsHidden()
                            .tint(.pink)
                        }

                        // Read Weight Toggle
                        HStack(spacing: Design.Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentPurple.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "scalemass.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.accentPurple)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Read Weight")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textPrimary)

                                Text("Use weight from Health for goals")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { profile?.readWeightFromHealth ?? false },
                                set: { profile?.readWeightFromHealth = $0 }
                            ))
                            .labelsHidden()
                            .tint(.pink)
                        }

                        // Last Sync Info
                        if let lastSync = profile?.lastHealthKitSync {
                            Divider()
                                .padding(.vertical, Design.Spacing.xxs)

                            HStack {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)

                                Text("Last synced \(lastSync.formatted(.relative(presentation: .named)))")
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)

                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )
        }
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            // Account Section
            makeAccountSection(syncManager: syncManager)

            // Health Section
            makeHealthSection()

            NewSectionHeader(title: "Appearance", icon: "paintbrush.fill", iconColor: Color.accentPurple)

            // Appearance & Units Card
            VStack(spacing: Design.Spacing.sm) {
                // Theme Picker
                HStack {
                    Text("Theme")
                        .font(.subheadline)
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    // Custom segmented control
                    HStack(spacing: 0) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    appearanceMode = mode
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 14))
                                    Text(mode.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(appearanceMode == mode ? Color.textPrimary : Color.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(appearanceMode == mode ? Color.cardBackground : Color.clear)
                                        .shadow(
                                            color: appearanceMode == mode ? Color.black.opacity(0.08) : .clear,
                                            radius: 4,
                                            y: 2
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.surfaceOverlay)
                    )
                }

                Divider()
                    .padding(.vertical, Design.Spacing.xxs)

                // Units Picker
                HStack {
                    Text("Units")
                        .font(.subheadline)
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    // Custom segmented control for units
                    HStack(spacing: 0) {
                        ForEach(MeasurementSystem.allCases) { system in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    measurementSystem = system
                                }
                            } label: {
                                VStack(spacing: 2) {
                                    Text(system.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(system.description)
                                        .font(.system(size: 9))
                                        .foregroundStyle(measurementSystem == system ? Color.textSecondary : Color.textSecondary.opacity(0.7))
                                }
                                .foregroundStyle(measurementSystem == system ? Color.textPrimary : Color.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(measurementSystem == system ? Color.cardBackground : Color.clear)
                                        .shadow(
                                            color: measurementSystem == system ? Color.black.opacity(0.08) : .clear,
                                            radius: 4,
                                            y: 2
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.surfaceOverlay)
                    )
                }
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )

            // Settings Section
            makeSettingsSection()

            // Developer Section
            makeDeveloperSection()
        }
    }

    // MARK: - Settings Section
    private func makeSettingsSection() -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Settings", icon: "gearshape.fill", iconColor: Color.textSecondary)

            VStack(spacing: Design.Spacing.sm) {
                // Notifications Row
                NavigationLink(destination: NotificationSettingsView()) {
                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentYellow.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.accentYellow)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textPrimary)

                            Text("Meal reminders & updates")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, Design.Spacing.xxs)

                // Help & Support Row
                NavigationLink(destination: HelpSupportNavigationView()) {
                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentPurple.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.accentPurple)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Help & Support")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textPrimary)

                            Text("FAQs, contact us, feedback")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, Design.Spacing.xxs)

                // About Row
                NavigationLink(destination: AboutNavigationView()) {
                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.mintVibrant.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.mintVibrant)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("About MealPrepAI")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textPrimary)

                            Text("Version, privacy & terms")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )
        }
    }

    // MARK: - Developer Section
    private func makeDeveloperSection() -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            NewSectionHeader(title: "Developer", icon: "wrench.and.screwdriver.fill", iconColor: Color.textSecondary)

            VStack(spacing: Design.Spacing.sm) {
                // Preview Onboarding Row
                Button(action: { showingOnboardingPreview = true }) {
                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentPurple.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.accentPurple)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Preview Onboarding")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textPrimary)

                            Text("View onboarding flow again")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, Design.Spacing.xxs)

                // Load Sample Data Row
                Button(action: loadSampleData) {
                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.mintVibrant.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "tray.and.arrow.down.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.mintVibrant)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Load Sample Meal Plan")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textPrimary)

                            Text("Generate test data for preview")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, Design.Spacing.xxs)

                // Clear All Data Row
                Button(action: clearAllData) {
                    HStack(spacing: Design.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "FF6B6B").opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "FF6B6B"))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clear All Data")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textPrimary)

                            Text("Reset app to initial state")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: Design.Shadow.card.color,
                        radius: Design.Shadow.card.radius,
                        y: Design.Shadow.card.y
                    )
            )
        }
    }

    private func loadSampleData() {
        guard let profile = profile else { return }
        SampleDataGenerator.generateSampleMealPlan(for: profile, in: modelContext)
    }

    private func clearAllData() {
        SampleDataGenerator.clearAllData(in: modelContext)
    }

    // MARK: - Authentication Handlers

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Link Apple ID to existing profile if exists
                if let existingProfile = profile {
                    existingProfile.linkAppleID(credential.user)
                }

                // Update auth manager
                authManager.upgradeFromGuest(credential: credential)

                // Enable sync after successful sign in
                if syncManager.canEnableSync {
                    syncManager.enableSync(for: credential.user)
                }
            }
        case .failure(let error):
            // Don't show error for user cancellation
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                return
            }
            print("Sign in failed: \(error.localizedDescription)")
        }
    }

    private func handleSignOut() {
        // Clear sync settings
        syncManager.disableSync()

        // Unlink Apple ID from profile
        if let existingProfile = profile {
            existingProfile.unlinkAppleID()
        }

        // Clear all local data
        SampleDataGenerator.clearAllData(in: modelContext)

        // Sign out from auth manager
        authManager.signOut()
    }

}


// MARK: - Onboarding Preview Wrapper
struct OnboardingPreviewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            OnboardingView {
                // Don't actually save on preview, just dismiss
                onDismiss()
            }

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.textPrimary, Color.cardBackground)
            }
            .padding(Design.Spacing.lg)
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthenticationManager())
        .environment(CloudKitSyncManager())
        .environment(HealthKitManager())
        .modelContainer(for: [UserProfile.self, Recipe.self], inMemory: true)
}
