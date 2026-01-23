import SwiftUI

// MARK: - About Navigation View
struct AboutNavigationView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        ScrollView {
            VStack(spacing: Design.Spacing.xl) {
                Spacer()
                    .frame(height: 20)

                // App Icon & Name
                VStack(spacing: Design.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(LinearGradient.purpleButtonGradient)
                            .frame(width: 100, height: 100)

                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                    }

                    Text("MealPrepAI")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }

                // Description
                Text("Your AI-powered meal planning assistant. Create personalized meal plans, track nutrition, and simplify grocery shopping - all in one app.")
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Design.Spacing.xl)

                // Links
                VStack(spacing: Design.Spacing.sm) {
                    aboutLink(icon: "doc.text", title: "Privacy Policy", url: "https://mealprepai.app/privacy")
                    aboutLink(icon: "doc.plaintext", title: "Terms of Service", url: "https://mealprepai.app/terms")
                    aboutLink(icon: "info.circle", title: "Open Source Licenses", url: "https://mealprepai.app/licenses")
                }
                .padding(.horizontal)

                Spacer()

                // Footer
                VStack(spacing: 4) {
                    Text("Made with love in 2026")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)

                    Text("MealPrepAI. All rights reserved.")
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary.opacity(0.7))
                }
                .padding(.bottom, Design.Spacing.xl)
            }
        }
        .background(LinearGradient.mintBackgroundGradient.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func aboutLink(icon: String, title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentPurple)
                    .frame(width: 24)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary.opacity(0.5))
            }
            .padding(Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(Color.cardBackground)
            )
        }
    }
}
