import SwiftUI
import SwiftData

struct EditPhysicalStatsView: View {
    @Bindable var profile: UserProfile
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Design.Spacing.lg) {
                // Age Section
                sectionCard(title: "Age", icon: "calendar") {
                    Picker("Age", selection: $profile.age) {
                        ForEach(13...100, id: \.self) { age in
                            Text("\(age) years").tag(age)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }

                // Gender Section
                sectionCard(title: "Gender", icon: "person.fill") {
                    VStack(spacing: Design.Spacing.sm) {
                        ForEach(Gender.allCases) { gender in
                            OnboardingSelectionCard(
                                title: gender.rawValue,
                                icon: gender.icon,
                                isSelected: profile.gender == gender
                            ) {
                                profile.gender = gender
                            }
                        }
                    }
                }

                // Height Section
                sectionCard(title: "Height", icon: "ruler") {
                    VStack(spacing: Design.Spacing.md) {
                        // Unit toggle
                        unitToggle

                        if measurementSystem == .metric {
                            // Metric: cm
                            VStack(spacing: Design.Spacing.xs) {
                                Text("\(Int(profile.heightCm)) cm")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)

                                Slider(
                                    value: $profile.heightCm,
                                    in: 120...220,
                                    step: 1
                                )
                                .tint(Color.accentPurple)
                                .accessibilityLabel("Height")
                                .accessibilityValue("\(Int(profile.heightCm)) centimeters")

                                HStack {
                                    Text("120 cm")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                    Spacer()
                                    Text("220 cm")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                }
                                .accessibilityHidden(true)
                            }
                        } else {
                            // Imperial: feet and inches
                            let totalInches = profile.heightCm / 2.54
                            let feet = Int(totalInches) / 12
                            let inches = Int(totalInches) % 12

                            VStack(spacing: Design.Spacing.xs) {
                                Text("\(feet)' \(inches)\"")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)

                                Slider(
                                    value: $profile.heightCm,
                                    in: 120...220,
                                    step: 2.54
                                )
                                .tint(Color.accentPurple)
                                .accessibilityLabel("Height")
                                .accessibilityValue("\(feet) feet \(inches) inches")

                                HStack {
                                    Text("3' 11\"")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                    Spacer()
                                    Text("7' 3\"")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                }
                                .accessibilityHidden(true)
                            }
                        }
                    }
                }

                // Weight Section
                sectionCard(title: "Weight", icon: "scalemass.fill") {
                    VStack(spacing: Design.Spacing.md) {
                        if measurementSystem == .metric {
                            // Metric: kg
                            VStack(spacing: Design.Spacing.xs) {
                                Text("\(Int(profile.weightKg)) kg")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)

                                Slider(
                                    value: $profile.weightKg,
                                    in: 30...200,
                                    step: 1
                                )
                                .tint(Color.accentPurple)
                                .accessibilityLabel("Weight")
                                .accessibilityValue("\(Int(profile.weightKg)) kilograms")

                                HStack {
                                    Text("30 kg")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                    Spacer()
                                    Text("200 kg")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                }
                                .accessibilityHidden(true)
                            }
                        } else {
                            // Imperial: lbs
                            let lbs = profile.weightKg * 2.20462

                            VStack(spacing: Design.Spacing.xs) {
                                Text("\(Int(lbs)) lbs")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.textPrimary)

                                Slider(
                                    value: $profile.weightKg,
                                    in: 30...200,
                                    step: 0.45359237
                                )
                                .tint(Color.accentPurple)
                                .accessibilityLabel("Weight")
                                .accessibilityValue("\(Int(lbs)) pounds")

                                HStack {
                                    Text("66 lbs")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                    Spacer()
                                    Text("441 lbs")
                                        .font(.caption)
                                        .foregroundStyle(Color.textSecondary)
                                }
                                .accessibilityHidden(true)
                            }
                        }
                    }
                }

                // Activity Level Section
                sectionCard(title: "Activity Level", icon: "figure.run") {
                    VStack(spacing: Design.Spacing.sm) {
                        ForEach(ActivityLevel.allCases) { level in
                            OnboardingSelectionCard(
                                title: level.rawValue,
                                description: level.description,
                                icon: level.icon,
                                isSelected: profile.activityLevel == level
                            ) {
                                profile.activityLevel = level
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Design.Spacing.md)
            .padding(.bottom, Design.Spacing.xxl)
        }
        .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
        .navigationTitle("Physical Stats")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Unit Toggle

    private var unitToggle: some View {
        HStack(spacing: 0) {
            ForEach(MeasurementSystem.allCases) { system in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        measurementSystem = system
                    }
                } label: {
                    Text(system.rawValue)
                        .font(.caption)
                        .fontWeight(measurementSystem == system ? .semibold : .regular)
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

    // MARK: - Section Card Builder

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.md) {
            HStack(spacing: Design.Spacing.sm) {
                Image(systemName: icon)
                    .font(Design.Typography.footnote)
                    .foregroundStyle(Color.accentPurple)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
            }

            content()
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

// MARK: - Gender Extension
private extension Gender {
    var icon: String {
        switch self {
        case .male: return "person.fill"
        case .female: return "person.fill"
        case .other: return "person.fill.questionmark"
        }
    }
}

#Preview {
    NavigationStack {
        EditPhysicalStatsView(profile: UserProfile(name: "Test"))
    }
    .modelContainer(for: UserProfile.self, inMemory: true)
}
