import SwiftUI
import StoreKit

// MARK: - Help & Support Navigation View
struct HelpSupportNavigationView: View {
    @Environment(\.requestReview) private var requestReview

    private let faqItems: [(question: String, answer: String)] = [
        ("How do I generate a meal plan?", "Go to the Today or Weekly Plan tab and tap 'Generate Meal Plan'. Fill in your preferences, choose your plan duration (1-14 days), and our AI will create a personalized plan."),
        ("Can I swap individual meals?", "Yes! Tap on any meal and use the 'Swap' button to generate a new meal alternative that fits your preferences."),
        ("How do I add my own recipes?", "Go to the Recipes tab and tap the + button in the top right. Fill in the recipe details to add your own creations."),
        ("How do allergies work?", "Set your allergies in your Profile. The AI will never suggest recipes containing your allergens."),
        ("Can I export my grocery list?", "Yes! Go to the Grocery tab and tap the share button to export or copy your list.")
    ]

    var body: some View {
        List {
            Section {
                ForEach(faqItems.indices, id: \.self) { index in
                    DisclosureGroup {
                        Text(faqItems[index].answer)
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .padding(.vertical, 8)
                    } label: {
                        Text(faqItems[index].question)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            } header: {
                Text("Frequently Asked Questions")
            }

            Section {
                Link(destination: AppURLs.emailSupport) {
                    Label("Email Support", systemImage: "envelope")
                }

                Link(destination: AppURLs.helpCenter) {
                    Label("Online Help Center", systemImage: "globe")
                }

                Link(destination: AppURLs.twitter) {
                    Label("Twitter @MealPrepAI", systemImage: "bubble.left")
                }
            } header: {
                Text("Contact Us")
            }

            Section {
                Button {
                    requestReview()
                } label: {
                    Label("Rate on App Store", systemImage: "star")
                }
                .accessibilityHint("Opens the App Store rating prompt")

                ShareLink(
                    item: AppURLs.appStore,
                    subject: Text("Check out MealPrepAI"),
                    message: Text("I've been using MealPrepAI to plan my meals. It's a great app for meal prep and nutrition tracking!")
                ) {
                    Label("Share MealPrepAI", systemImage: "square.and.arrow.up")
                }
            } header: {
                Text("Support Us")
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}
