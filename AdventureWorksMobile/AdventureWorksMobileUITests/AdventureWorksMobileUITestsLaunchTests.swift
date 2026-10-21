//
//  AdventureWorksMobileUITestsLaunchTests.swift
//  AdventureWorksMobileUITests
//
//  Created by Nathan Bergman on 9/20/26.
//

import XCTest

final class AdventureWorksMobileUITestsLaunchTests: XCTestCase {

    // Run once per UI setup, like light and dark mode.
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Add steps to run before the screenshot. Docs: https://developer.apple.com/documentation/xcuiautomation

        // Save a screenshot of the launch screen with the test results.
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
