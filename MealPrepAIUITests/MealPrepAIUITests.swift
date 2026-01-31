//
//  MealPrepAIUITests.swift
//  MealPrepAIUITests
//
//  Created by Sebastián Kučera on 17.01.2026.
//

import XCTest

final class MealPrepAIUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    // MARK: - App Launch

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        // App should launch without crashing
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    // MARK: - Tab Navigation

    @MainActor
    func testTabNavigationExists() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify tab bar exists
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
    }

    @MainActor
    func testTabBarHasFiveTabs() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            XCTFail("Tab bar not found - user may be in onboarding")
            return
        }
        // 5 tabs: Today, Plan, Grocery, Recipes, Profile
        XCTAssertEqual(tabBar.buttons.count, 5)
    }

    // MARK: - Launch Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
