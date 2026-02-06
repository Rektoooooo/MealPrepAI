import SwiftUI
import UIKit

// MARK: - In-Memory Image Cache

/// Thread-safe in-memory image cache backed by NSCache.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50_000_000 // ~50 MB
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

// MARK: - CachedAsyncImage

/// Drop-in replacement for AsyncImage that uses an in-memory NSCache
/// and URLSession's disk cache for persistent caching.
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (AsyncImagePhase) -> Content

    @State private var phase: AsyncImagePhase = .empty

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .task(id: url) {
                await load()
            }
    }

    private func load() async {
        guard let url else {
            phase = .empty
            return
        }

        // Check in-memory cache first
        if let cached = ImageCache.shared.image(for: url) {
            phase = .success(Image(uiImage: cached))
            return
        }

        phase = .empty

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // Downsample to reasonable size for display
            guard let uiImage = UIImage.downsample(data: data, maxDimension: 400) ?? UIImage(data: data) else {
                phase = .failure(URLError(.cannotDecodeContentData))
                return
            }

            ImageCache.shared.insert(uiImage, for: url)
            phase = .success(Image(uiImage: uiImage))
        } catch {
            phase = .failure(error)
        }
    }
}

// Convenience initializer matching common AsyncImage usage
extension CachedAsyncImage where Content == _ConditionalContent<_ConditionalContent<Image, ProgressView<EmptyView, EmptyView>>, Color> {
    init(url: URL?) {
        self.init(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable()
            case .empty:
                ProgressView()
            case .failure:
                Color.clear
            }
        }
    }
}
