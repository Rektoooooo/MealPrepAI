//
//  ContentView.swift
//  MealPrepAI
//
//  Created by Sebastian Kucera on 17.01.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area
            Group {
                switch selectedTab {
                case 0: TodayView()
                case 1: WeeklyPlanView()
                case 2: GroceryListView()
                case 3: RecipesView()
                case 4: ProfileView()
                default: TodayView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom floating tab bar
            FloatingTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Floating Tab Bar
struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var tabAnimation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tabs: [(icon: String, selectedIcon: String, label: String)] = [
        ("house", "house.fill", "Today"),
        ("calendar", "calendar", "Plan"),
        ("cart", "cart.fill", "Grocery"),
        ("book", "book.fill", "Recipes"),
        ("person", "person.fill", "Profile")
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<tabs.count, id: \.self) { index in
                let isSelected = selectedTab == index
                Button {
                    withAnimation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = index
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isSelected ? tabs[index].selectedIcon : tabs[index].icon)
                            .font(.system(size: isSelected ? 18 : 21, weight: isSelected ? .semibold : .medium))
                            .symbolEffect(.bounce, options: reduceMotion ? .nonRepeating : .default, value: selectedTab == index)

                        if isSelected {
                            Text(tabs[index].label)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .leading)).animation(.easeOut(duration: 0.2).delay(0.05)),
                                    removal: .opacity.animation(.easeIn(duration: 0.1))
                                ))
                        }
                    }
                    .foregroundStyle(isSelected ? Color.white : Color(light: Color(hex: "8E8E93"), dark: Color(hex: "8E8E93")))
                    .frame(minWidth: isSelected ? nil : 50, minHeight: 50)
                    .fixedSize(horizontal: isSelected, vertical: false)
                    .padding(.horizontal, isSelected ? 14 : 0)
                    .frame(maxWidth: isSelected ? nil : .infinity)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Color(hex: "1C1C1E"))
                                .matchedGeometryEffect(id: "activeTab", in: tabAnimation)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tabs[index].label)
                .accessibilityValue(isSelected ? "Selected" : "")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 20, y: 8)
                .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }
}

#Preview {
    ContentView()
}
