//
//  AdventureWorksMobileUITests.swift
//  AdventureWorksMobileUITests
//
//  Created by Nathan Bergman on 9/20/26.
//

import XCTest

final class AdventureWorksMobileUITests: XCTestCase {

    override func setUpWithError() throws {
        // Stop at the first failure.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testLoginRequiresUsernameAndPassword() throws {
        let app = XCUIApplication()
        // Start signed out.
        app.launchArguments.append("--ui-testing-reset-auth")
        app.launch()

        let username = app.textFields["usernameField"]
        let password = app.secureTextFields["passwordField"]
        let loginButton = app.buttons["loginButton"]

        XCTAssertTrue(username.waitForExistence(timeout: 5))
        XCTAssertTrue(password.exists)
        XCTAssertFalse(loginButton.isEnabled)

        username.tap()
        username.typeText("employee")
        password.tap()
        password.typeText("password")

        XCTAssertTrue(loginButton.isEnabled)
    }

    @MainActor
    func testTabsAreHiddenBeforeSignIn() throws {
        let app = XCUIApplication()
        // Start signed out.
        app.launchArguments.append("--ui-testing-reset-auth")
        app.launch()

        XCTAssertTrue(app.textFields["usernameField"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.secureTextFields["passwordField"].exists)
        XCTAssertTrue(app.buttons["loginButton"].exists)

        XCTAssertEqual(app.tabBars.count, 0, "Signed-out users should not see a tab bar.")
        for title in ["Dashboard", "Products", "Orders", "Account"] {
            XCTAssertFalse(app.buttons[title].exists, "The \(title) tab must be hidden before sign-in.")
        }

        for identifier in ["dashboardView", "productView", "customerOrderView", "accountView"] {
            XCTAssertFalse(app.descendants(matching: .any)[identifier].exists,
                           "Protected screens must not appear before sign-in.")
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // Measures how long the app takes to launch.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
