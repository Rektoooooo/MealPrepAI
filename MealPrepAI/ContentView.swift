//
//  ContentView.swift
//  MealPrepAI
//
//  Created by Sebastián Kučera on 17.01.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(0)

            WeeklyPlanView()
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
                .tag(1)

            GroceryListView()
                .tabItem {
                    Label("Grocery", systemImage: "cart.fill")
                }
                .tag(2)

            RecipesView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(Color.brandGreen)
    }
}

#Preview {
    ContentView()
}
