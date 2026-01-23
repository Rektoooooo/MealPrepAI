import SwiftUI

// MARK: - Recipe Skeleton View
/// Loading skeleton placeholder for recipes
/// Shows while recipes are being fetched from Firebase
struct RecipeSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: Design.Spacing.lg) {
            // Featured card skeleton
            FeaturedRecipeSkeleton()

            // Section header skeleton
            HStack {
                SkeletonBox(width: 100, height: 20)
                Spacer()
            }
            .padding(.horizontal, Design.Spacing.lg)

            // Grid skeletons
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Design.Spacing.md),
                GridItem(.flexible(), spacing: Design.Spacing.md)
            ], spacing: Design.Spacing.md) {
                ForEach(0..<6, id: \.self) { _ in
                    RecipeCardSkeleton()
                }
            }
            .padding(.horizontal, Design.Spacing.lg)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Featured Recipe Skeleton
struct FeaturedRecipeSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: Design.Spacing.md) {
            // Section header
            HStack {
                SkeletonBox(width: 80, height: 18)
                Spacer()
            }
            .padding(.horizontal, Design.Spacing.lg)

            // Featured card
            ZStack(alignment: .bottomLeading) {
                SkeletonBox(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: Design.Radius.featured))

                VStack(alignment: .leading, spacing: Design.Spacing.sm) {
                    SkeletonBox(width: 60, height: 24, cornerRadius: Design.Radius.full)
                    SkeletonBox(width: 180, height: 24)
                    SkeletonBox(width: 120, height: 16)
                }
                .padding(Design.Spacing.lg)
            }
            .padding(.horizontal, Design.Spacing.lg)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Recipe Card Skeleton
struct RecipeCardSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.sm) {
            // Image placeholder
            SkeletonBox(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: Design.Radius.md))

            // Title
            SkeletonBox(width: .random(in: 80...140), height: 16)

            // Subtitle
            SkeletonBox(width: .random(in: 60...100), height: 14)

            // Stats row
            HStack(spacing: Design.Spacing.sm) {
                SkeletonBox(width: 40, height: 14)
                SkeletonBox(width: 50, height: 14)
            }
        }
        .padding(Design.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(Color.cardBackground)
                .shadow(
                    color: Design.Shadow.sm.color,
                    radius: Design.Shadow.sm.radius,
                    y: Design.Shadow.sm.y
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Skeleton Box
/// A shimmer loading placeholder box
struct SkeletonBox: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = Design.Radius.sm

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.2)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Shimmer Effect Modifier
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.4),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                    .mask(content)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Inline Recipe Skeleton
/// Compact skeleton for list items
struct InlineRecipeSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: Design.Spacing.md) {
            // Thumbnail
            SkeletonBox(width: 60, height: 60, cornerRadius: Design.Radius.md)

            VStack(alignment: .leading, spacing: Design.Spacing.xs) {
                SkeletonBox(width: 140, height: 16)
                SkeletonBox(width: 80, height: 14)
            }

            Spacer()

            SkeletonBox(width: 40, height: 30, cornerRadius: Design.Radius.sm)
        }
        .padding(Design.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Design.Radius.card)
                .fill(Color.cardBackground)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Recipe List Skeleton
/// Full list loading skeleton
struct RecipeListSkeleton: View {
    let count: Int

    init(count: Int = 5) {
        self.count = count
    }

    var body: some View {
        VStack(spacing: Design.Spacing.md) {
            ForEach(0..<count, id: \.self) { _ in
                InlineRecipeSkeleton()
            }
        }
        .padding(.horizontal, Design.Spacing.lg)
    }
}

// MARK: - View Extension
extension View {
    /// Apply shimmer loading effect
    func shimmerLoading() -> some View {
        self.modifier(ShimmerEffect())
    }
}

// MARK: - Preview
#Preview("Recipe Skeleton View") {
    ScrollView {
        RecipeSkeletonView()
    }
    .background(LinearGradient.mintBackgroundGradient)
}

#Preview("Recipe Card Skeleton") {
    HStack {
        RecipeCardSkeleton()
        RecipeCardSkeleton()
    }
    .padding()
    .background(LinearGradient.mintBackgroundGradient)
}

#Preview("Inline Skeleton") {
    VStack {
        InlineRecipeSkeleton()
        InlineRecipeSkeleton()
        InlineRecipeSkeleton()
    }
    .padding()
    .background(LinearGradient.mintBackgroundGradient)
}
