import SwiftUI
import PhotosUI

struct ProfileImagePicker: View {
    @Binding var selectedEmoji: String
    @Binding var profileImageData: Data?

    @State private var selectedMode: ImagePickerMode = .emoji
    @State private var selectedPhotoItem: PhotosPickerItem?

    enum ImagePickerMode: String, CaseIterable {
        case emoji = "Emoji"
        case photo = "Photo"
    }

    var body: some View {
        VStack(spacing: Design.Spacing.lg) {
            // Avatar Preview
            avatarPreview

            // Mode Selector
            modeSelector

            // Content based on mode
            if selectedMode == .emoji {
                emojiGrid
            } else {
                photoPickerSection
            }
        }
    }

    // MARK: - Avatar Preview

    private var avatarPreview: some View {
        ZStack {
            Circle()
                .stroke(LinearGradient.purpleButtonGradient, lineWidth: 4)
                .frame(width: 120, height: 120)

            if let imageData = profileImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(LinearGradient.purpleButtonGradient)
                    .frame(width: 110, height: 110)

                Text(selectedEmoji)
                    .font(.system(size: 56))
            }
        }
        .animation(.spring(response: 0.3), value: profileImageData)
        .animation(.spring(response: 0.3), value: selectedEmoji)
        .accessibilityLabel(profileImageData != nil ? "Profile photo" : "Profile avatar, \(selectedEmoji)")
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        HStack(spacing: 0) {
            ForEach(ImagePickerMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedMode == mode ? .semibold : .regular)
                        .foregroundStyle(selectedMode == mode ? Color.textPrimary : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Design.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(selectedMode == mode ? Color.cardBackground : Color.clear)
                                .shadow(
                                    color: selectedMode == mode ? Color.black.opacity(0.08) : .clear,
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
            Capsule()
                .fill(Color.surfaceOverlay)
        )
        .padding(.horizontal, Design.Spacing.xl)
    }

    // MARK: - Emoji Grid

    private var emojiGrid: some View {
        VStack(spacing: Design.Spacing.md) {
            let columns = [GridItem(.adaptive(minimum: 60), spacing: Design.Spacing.md)]

            let avatars = [
                "🍳", "🥗", "🍕", "🌮",
                "🍜", "🍣", "🥑", "🍱",
                "🧑‍🍳", "👨‍🍳", "👩‍🍳", "🦊",
                "🐻", "🐼", "🦁", "🐸"
            ]

            LazyVGrid(columns: columns, spacing: Design.Spacing.md) {
                ForEach(avatars, id: \.self) { emoji in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedEmoji = emoji
                        // Clear photo when selecting emoji
                        profileImageData = nil
                    } label: {
                        Text(emoji)
                            .font(.system(size: 36))
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(selectedEmoji == emoji && profileImageData == nil
                                          ? Color.accentPurple.opacity(0.2)
                                          : Color.surfaceOverlay)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        selectedEmoji == emoji && profileImageData == nil
                                            ? Color.accentPurple
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .scaleEffect(selectedEmoji == emoji && profileImageData == nil ? 1.1 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedEmoji)
                    .accessibilityLabel("Avatar \(emoji)")
                    .accessibilityAddTraits(selectedEmoji == emoji && profileImageData == nil ? .isSelected : [])
                }
            }
            .padding(.horizontal, Design.Spacing.md)
        }
    }

    // MARK: - Photo Picker Section

    private var photoPickerSection: some View {
        VStack(spacing: Design.Spacing.lg) {
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack(spacing: Design.Spacing.sm) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18))
                    Text(profileImageData != nil ? "Change Photo" : "Choose Photo")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Design.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Design.Radius.md)
                        .fill(LinearGradient.purpleButtonGradient)
                )
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                Task {
                    if let newValue,
                       let data = try? await newValue.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            profileImageData = data
                        }
                    }
                }
            }

            if profileImageData != nil {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation {
                        profileImageData = nil
                        selectedPhotoItem = nil
                    }
                } label: {
                    HStack(spacing: Design.Spacing.xs) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text("Remove Photo")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color(hex: "FF6B6B"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Design.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Design.Radius.md)
                            .fill(Color(hex: "FF6B6B").opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove photo")
            }

            Text("Choose a photo from your library to use as your profile picture")
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.horizontal, Design.Spacing.md)
    }
}

#Preview {
    ProfileImagePicker(
        selectedEmoji: .constant("🍳"),
        profileImageData: .constant(nil)
    )
    .padding()
}
