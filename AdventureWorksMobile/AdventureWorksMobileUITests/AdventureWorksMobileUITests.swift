//
//  AdventureWorksMobileUITests.swift
//  AdventureWorksMobileUITests
//
//  Created by Nathan Bergman on 9/20/26.
//

import XCTest

final class AdventureWorksMobileUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testLoginRequiresUsernameAndPassword() throws {
        let app = XCUIApplication()
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
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
