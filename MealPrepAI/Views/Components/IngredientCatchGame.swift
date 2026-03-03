import SwiftUI
import UIKit

// MARK: - Game Data Structures

enum GameItemType {
    case ingredient
    case bomb
}

struct GameItem: Identifiable {
    let id = UUID()
    let emoji: String
    let type: GameItemType
    let createdAt: Date
    let duration: TimeInterval        // 1.8 - 2.8s
    // Arc trajectory params (quadratic bezier)
    let startX: CGFloat               // 0-1 fraction
    let peakX: CGFloat                // 0-1 fraction
    let peakY: CGFloat                // 0.15-0.35 fraction from top
    let endX: CGFloat                 // 0-1 fraction
    let rotationSpeed: Double         // radians per second
    let rotationDirection: Double     // -1 or 1
    var isCaught: Bool = false
}

struct FloatingScoreText: Identifiable {
    let id = UUID()
    let text: String
    let position: CGPoint
    let color: Color
    let createdAt: Date
}

struct SplashParticle: Identifiable {
    let id = UUID()
    let origin: CGPoint
    let angle: Double                 // radians
    let distance: CGFloat             // max travel distance
    let createdAt: Date
}

// MARK: - Ingredient Catch Game

struct IngredientCatchGame: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var items: [GameItem] = []
    @State private var score: Int = 0
    @State private var combo: Int = 0
    @State private var lives: Int = 3
    @State private var isGameOver: Bool = false
    @State private var showHint = true
    @State private var comboText: String? = nil
    @State private var floatingScores: [FloatingScoreText] = []
    @State private var splashParticles: [SplashParticle] = []
    @State private var screenShakeOffset: CGSize = .zero
    @State private var spawnTimer: Timer?

    private let emojiPool = [
        "🥑", "🍅", "🥕", "🧅", "🫑", "🥦", "🍋", "🌽",
        "🧄", "🥒", "🍗", "🥩", "🍳", "🧀", "🫐", "🍌"
    ]

    var body: some View {
        if reduceMotion {
            staticFallback
        } else {
            gameView
                .onAppear { startGame() }
                .onDisappear { stopGame() }
        }
    }

    // MARK: - Game View

    private var gameView: some View {
        TimelineView(.animation) { context in
            let now = context.date

            GeometryReader { geo in
                ZStack {
                    // Splash particles
                    ForEach(splashParticles) { particle in
                        splashParticleView(particle: particle, now: now)
                    }

                    // Arc items
                    ForEach(items) { item in
                        arcItemView(item: item, now: now, size: geo.size)
                    }

                    // Floating score texts
                    ForEach(floatingScores) { floating in
                        floatingScoreView(floating: floating, now: now)
                    }

                    // Hint text
                    if showHint {
                        Text("Tap the ingredients!")
                            .font(.system(.headline, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                            .padding(.horizontal, Design.Spacing.lg)
                            .padding(.vertical, Design.Spacing.sm)
                            .background(.ultraThinMaterial, in: Capsule())
                            .position(x: geo.size.width / 2, y: geo.size.height * 0.45)
                            .transition(.opacity)
                    }

                    // Lives (top-left) — hide when game over
                    if !isGameOver {
                        livesView
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.leading, Design.Spacing.md)
                            .padding(.top, Design.Spacing.sm)

                        // Score badge (bottom-center)
                        scoreBadge
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, Design.Spacing.lg)
                    }

                    // Combo text (center)
                    if let comboLabel = comboText {
                        comboTextView(label: comboLabel)
                            .position(x: geo.size.width / 2, y: geo.size.height * 0.32)
                    }

                    // Game over overlay
                    if isGameOver {
                        gameOverOverlay(size: geo.size)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .offset(screenShakeOffset)
            }
        }
    }

    // MARK: - Arc Item View

    @ViewBuilder
    private func arcItemView(item: GameItem, now: Date, size: CGSize) -> some View {
        let elapsed = now.timeIntervalSince(item.createdAt)
        let t = min(elapsed / item.duration, 1.0)

        if !item.isCaught && t <= 1.0 {
            let position = bezierPosition(item: item, t: t, size: size)
            let rotation = item.rotationSpeed * elapsed * item.rotationDirection

            Text(item.emoji)
                .font(.system(size: 44))
                .rotationEffect(.radians(rotation))
                .shadow(
                    color: item.type == .bomb
                        ? Color.red.opacity(0.4)
                        : Color.black.opacity(0.15),
                    radius: item.type == .bomb ? 8 : 4,
                    y: 3
                )
                .scaleEffect(t > 0.9 ? max(0, 1 - (t - 0.9) / 0.1) : 1.0)
                .opacity(t > 0.9 ? max(0, 1 - (t - 0.9) / 0.1) : 1.0)
                .position(position)
                .onTapGesture {
                    catchItem(item, at: position)
                }
        }
    }

    // MARK: - Bezier Position

    private func bezierPosition(item: GameItem, t: CGFloat, size: CGSize) -> CGPoint {
        // P0 = start (bottom), P1 = peak (top area), P2 = end (bottom)
        let p0 = CGPoint(x: size.width * item.startX, y: size.height + 50)
        let p1 = CGPoint(x: size.width * item.peakX, y: size.height * item.peakY)
        let p2 = CGPoint(x: size.width * item.endX, y: size.height + 50)

        let oneMinusT = 1.0 - t
        let x = oneMinusT * oneMinusT * p0.x + 2 * oneMinusT * t * p1.x + t * t * p2.x
        let y = oneMinusT * oneMinusT * p0.y + 2 * oneMinusT * t * p1.y + t * t * p2.y
        return CGPoint(x: x, y: y)
    }

    // MARK: - Splash Particle View

    @ViewBuilder
    private func splashParticleView(particle: SplashParticle, now: Date) -> some View {
        let elapsed = now.timeIntervalSince(particle.createdAt)
        let life: Double = 0.4
        let progress = min(elapsed / life, 1.0)

        if progress < 1.0 {
            let dx = cos(particle.angle) * particle.distance * progress
            let dy = sin(particle.angle) * particle.distance * progress

            Circle()
                .fill(Color.accentOrange)
                .frame(width: 8 * (1 - progress), height: 8 * (1 - progress))
                .opacity(1 - progress)
                .position(
                    x: particle.origin.x + dx,
                    y: particle.origin.y + dy
                )
        }
    }

    // MARK: - Floating Score View

    @ViewBuilder
    private func floatingScoreView(floating: FloatingScoreText, now: Date) -> some View {
        let elapsed = now.timeIntervalSince(floating.createdAt)
        let life: Double = 0.8
        let progress = min(elapsed / life, 1.0)

        if progress < 1.0 {
            let scale = progress < 0.15
                ? 0.5 + (progress / 0.15) * 0.7
                : 1.2 - progress * 0.3

            Text(floating.text)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(floating.color)
                .scaleEffect(scale)
                .opacity(1 - progress * progress)
                .position(
                    x: floating.position.x,
                    y: floating.position.y - 60 * progress
                )
        }
    }

    // MARK: - Lives View

    private var livesView: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < lives ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(i < lives ? Color.accentPink : Color.textTertiary)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Score Badge

    private var scoreBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.yellow)

            Text("\(score)")
                .font(.system(.title3, weight: .bold))
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())

            if combo >= 3 {
                Text("🔥")
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, Design.Spacing.lg)
        .padding(.vertical, Design.Spacing.sm)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Combo Text

    private func comboTextView(label: String) -> some View {
        Text(label)
            .font(.system(size: 36, weight: .heavy))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.accentOrange, Color.accentPink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color.accentOrange.opacity(0.5), radius: 12)
            .shadow(color: Color.accentPink.opacity(0.3), radius: 20)
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Game Over Overlay

    private func gameOverOverlay(size: CGSize) -> some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Trophy emoji
                Text("🏆")
                    .font(.system(size: 56))

                Text("Game Over!")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.textPrimary)

                // Score with accent background
                VStack(spacing: 6) {
                    Text("SCORE")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(Color.textSecondary)
                        .tracking(2)

                    Text("\(score)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentOrange, Color.accentPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("Your meal plan is almost ready!")
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)

                // Play Again button
                Button {
                    restartGame()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .bold))
                        Text("Play Again")
                            .font(.system(.body, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentOrange, Color.accentPink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color.accentOrange.opacity(0.4), radius: 12, y: 6)
                }
            }
            .padding(32)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.2), radius: 30, y: 15)
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
    }

    private func restartGame() {
        items.removeAll()
        floatingScores.removeAll()
        splashParticles.removeAll()
        score = 0
        combo = 0
        lives = 3
        comboText = nil
        screenShakeOffset = .zero
        isGameOver = false
        showHint = true
        startGame()
    }

    // MARK: - Static Fallback

    private var staticFallback: some View {
        VStack(spacing: Design.Spacing.lg) {
            Spacer()
            Image(systemName: "fork.knife")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(Color.textSecondary)
            Text("Your meal plan is being prepared...")
                .font(.system(.body, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Design.Spacing.xl)
    }

    // MARK: - Game Lifecycle

    private func startGame() {
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            guard !isGameOver else { return }
            spawnWave()
            pruneAll()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.5)) {
                showHint = false
            }
        }
    }

    private func stopGame() {
        spawnTimer?.invalidate()
        spawnTimer = nil
    }

    // MARK: - Spawning

    private func spawnWave() {
        let count = Int.random(in: 2...4)
        for i in 0..<count {
            let delay = Double(i) * Double.random(in: 0.1...0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard !isGameOver else { return }
                spawnItem()
            }
        }
    }

    private func spawnItem() {
        let isBomb = Double.random(in: 0...1) < 0.15
        let emoji = isBomb ? "💣" : emojiPool.randomElement()!
        let type: GameItemType = isBomb ? .bomb : .ingredient
        let duration = Double.random(in: 1.8...2.8)

        let startX = CGFloat.random(in: 0.15...0.85)
        let peakX = CGFloat.random(in: 0.15...0.85)
        let peakY = CGFloat.random(in: 0.05...0.18)
        // End X drifts from peak
        let endX = min(max(peakX + CGFloat.random(in: -0.3...0.3), 0.05), 0.95)

        let item = GameItem(
            emoji: emoji,
            type: type,
            createdAt: Date(),
            duration: duration,
            startX: startX,
            peakX: peakX,
            peakY: peakY,
            endX: endX,
            rotationSpeed: Double.random(in: 1.5...4.0),
            rotationDirection: Bool.random() ? 1.0 : -1.0
        )
        items.append(item)
    }

    // MARK: - Pruning

    private func pruneAll() {
        let now = Date()

        // Prune items past duration + buffer
        let expiredItems = items.filter { item in
            if item.isCaught { return true }
            let elapsed = now.timeIntervalSince(item.createdAt)
            return elapsed > item.duration + 0.3
        }

        // Missed ingredients reset combo (but no life penalty)
        for item in expiredItems {
            if !item.isCaught && item.type == .ingredient {
                let elapsed = now.timeIntervalSince(item.createdAt)
                if elapsed > item.duration {
                    combo = 0
                }
            }
        }

        items.removeAll { item in
            if item.isCaught { return true }
            return now.timeIntervalSince(item.createdAt) > item.duration + 0.3
        }

        // Prune floating scores
        floatingScores.removeAll { now.timeIntervalSince($0.createdAt) > 1.0 }

        // Prune splash particles
        splashParticles.removeAll { now.timeIntervalSince($0.createdAt) > 0.5 }
    }

    // MARK: - Catch Logic

    private func catchItem(_ item: GameItem, at position: CGPoint) {
        guard !isGameOver else { return }
        guard let index = items.firstIndex(where: { $0.id == item.id && !$0.isCaught }) else { return }
        items[index].isCaught = true

        if item.type == .bomb {
            handleBombTap(at: position)
        } else {
            handleIngredientTap(at: position)
        }
    }

    private func handleIngredientTap(at position: CGPoint) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        combo += 1
        let multiplier: Int
        if combo >= 7 { multiplier = 4 }
        else if combo >= 5 { multiplier = 3 }
        else if combo >= 3 { multiplier = 2 }
        else { multiplier = 1 }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            score += multiplier
        }

        // Splash particles
        let particleCount = Int.random(in: 4...6)
        for i in 0..<particleCount {
            let angle = (Double(i) / Double(particleCount)) * 2 * .pi + Double.random(in: -0.3...0.3)
            let distance = CGFloat.random(in: 25...50)
            splashParticles.append(
                SplashParticle(origin: position, angle: angle, distance: distance, createdAt: Date())
            )
        }

        // Floating score
        let scoreColor: Color = multiplier >= 3 ? Color.accentPink : Color.accentOrange
        floatingScores.append(
            FloatingScoreText(
                text: "+\(multiplier)",
                position: CGPoint(x: position.x, y: position.y - 10),
                color: scoreColor,
                createdAt: Date()
            )
        )

        // Combo text
        if combo >= 3 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                comboText = "x\(multiplier)!"
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.3)) {
                    comboText = nil
                }
            }
        }
    }

    private func handleBombTap(at position: CGPoint) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        combo = 0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            comboText = nil
        }

        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            lives -= 1
        }

        // Screen shake sequence
        triggerScreenShake()

        if lives <= 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                isGameOver = true
            }
            spawnTimer?.invalidate()
            spawnTimer = nil
        }
    }

    private func triggerScreenShake() {
        let offsets: [(CGSize, Double)] = [
            (CGSize(width: -8, height: 0), 0.0),
            (CGSize(width: 8, height: -4), 0.05),
            (CGSize(width: -6, height: 4), 0.10),
            (CGSize(width: 6, height: -2), 0.15),
            (CGSize(width: -3, height: 2), 0.20),
            (.zero, 0.30)
        ]

        for (offset, delay) in offsets {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.linear(duration: 0.05)) {
                    screenShakeOffset = offset
                }
            }
        }
    }
}

// MARK: - Standalone Game View

struct LoadingGamePreviewView: View {
    @Environment(\.colorScheme) private var colorScheme
    var onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            IngredientCatchGame()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(hex: "1C1C1E"), Color(hex: "1A1A1C"), Color.backgroundPrimary]
                            : [Color(hex: "FFF8F5"), Color(hex: "FFFCFA"), Color.backgroundPrimary],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .ignoresSafeArea()
                )

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.top, 12)
            .padding(.trailing, Design.Spacing.md)
        }
    }
}
