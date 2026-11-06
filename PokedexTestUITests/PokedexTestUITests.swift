//
//  PokedexUITests.swift
//  PokedexUITests
//
//  Created by Dian Maisara on 6/11/26.
//

import XCTest

final class PokedexUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
    }

    // MARK: - Helpers

    /// Adds a Pokeymon through the form.
    private func addPokeymon(named name: String, attackIncrements: Int, defenseIncrements: Int) {
        // Tap the navigation bar Add button
        app.navigationBars.buttons["Add"].tap()

        // Fill the name
        let nameField = app.textFields["Pokeymon Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Name text field must exist")
        nameField.tap()
        nameField.typeText(name)

        // Leave the type picker at its default selection

        // Increment steppers: first is Attack, second is Defence
        let steppers = app.steppers
        if steppers.count >= 1 {
            let attackStepper = steppers.element(boundBy: 0)
            for _ in 0..<attackIncrements { attackStepper.buttons["Increment"].tap() }
        }
        if steppers.count >= 2 {
            let defenseStepper = steppers.element(boundBy: 1)
            for _ in 0..<defenseIncrements { defenseStepper.buttons["Increment"].tap() }
        }

        // Set the date captured to 15 January 2024.
        // All the wheels on the form are in app.pickerWheels: wheel 0 is the type picker,
        // then the date picker's wheels. On this simulator the order is day, month, year
        // (it can change with the device region, e.g. month, day, year in the US).
        let wheels = app.pickerWheels
        let dayWheel = wheels.element(boundBy: 1)
        if !dayWheel.isHittable { app.swipeUp() } // the date picker is near the bottom
        dayWheel.adjust(toPickerWheelValue: "15")
        wheels.element(boundBy: 2).adjust(toPickerWheelValue: "January")
        wheels.element(boundBy: 3).adjust(toPickerWheelValue: "2024")

        // Save
        app.navigationBars.buttons["Save"].tap()
    }

    /// Clears any existing text in a text field and types the given text.
    private func clearAndTypeText(_ textField: XCUIElement, text: String) {
        textField.tap()

        // Try robust clear by sending deletes equal to current value length
        if let current = textField.value as? String, current.isEmpty == false, current != textField.placeholderValue {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
            textField.typeText(deleteString)
        } else {
            // Fallback: Select All if the system shows the editing menu
            if app.menuItems["Select All"].waitForExistence(timeout: 0.5) {
                app.menuItems["Select All"].tap()
                app.keys["delete"].tap()
            }
        }

        textField.typeText(text)
    }

    /// Returns the value label inside a `.value1` cell by picking the static text that is not the title.
    private func findValueLabel(inRowWithTitle title: String) -> XCUIElement {
        let row = app.tables.cells.containing(.staticText, identifier: title).element
        let texts = row.staticTexts.allElementsBoundByIndex
        // Prefer the label that does not equal the title
        if let other = texts.first(where: { $0.label != title }) {
            return other
        }
        // Fallback: return the second static text if present, otherwise the first
        return texts.count >= 2 ? texts[1] : texts[0]
    }

    /// Asserts that on the Details table, the row with `title` has its value label equal to `expected`.
    private func assertDetailValue(forTitle title: String, equals expected: String) {
        let cell = app.tables.cells.containing(.staticText, identifier: title).element
        XCTAssertTrue(cell.waitForExistence(timeout: 3), "Row titled \(title) should exist")

        let valueLabel = findValueLabel(inRowWithTitle: title)
        XCTAssertTrue(valueLabel.waitForExistence(timeout: 3), "Value label should exist in \(title) row")
        XCTAssertEqual(valueLabel.label, expected, "Edited value should be visible in the \(title) row")
    }

    // MARK: - Tests

    @MainActor
    func testCRUDPokeymonFlow() throws {
        let originalName = "Potato"
        let editedName = "Baked \(originalName)"

        // 1) Add a new Pokeymon and verify it appears in the list
        addPokeymon(named: originalName, attackIncrements: 10, defenseIncrements: 3)
        XCTAssertTrue(app.tables.staticTexts[originalName].waitForExistence(timeout: 3),
                      "Newly added item should be visible in the list")
        // The list cell shows the date in short format, so build the same text the app does
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        let pickedDate = DateComponents(calendar: .current, year: 2024, month: 1, day: 15).date!
        let expectedDateText = "📅 \(formatter.string(from: pickedDate))"
        XCTAssertTrue(app.tables.staticTexts[expectedDateText].exists,
                      "List should show the date we picked (\(expectedDateText))")

        // 2) Navigate to detail page and verify you're there
        app.tables.staticTexts[originalName].tap()
        XCTAssertTrue(app.navigationBars["Details"].waitForExistence(timeout: 3),
                      "Should be on the detail screen")
        assertDetailValue(forTitle: "Name", equals: originalName)

        // 3) Edit the name, go back and verify the new name
        app.navigationBars.buttons["Edit"].tap()
        XCTAssertTrue(app.navigationBars["Edit Pokeymon"].waitForExistence(timeout: 3),
                      "Edit form should appear")

        clearAndTypeText(app.textFields["Pokeymon Name"], text: editedName)
        app.navigationBars.buttons["Save"].tap()

        // Back on the detail screen, the new name should show
        assertDetailValue(forTitle: "Name", equals: editedName)

        // Go back to the list (the back button is the first button in the nav bar)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.tables.staticTexts[editedName].waitForExistence(timeout: 3),
                      "List should show the edited name")
        XCTAssertFalse(app.tables.staticTexts[originalName].exists,
                       "Old name should no longer be in the list")

        // 4) Delete and verify it's gone
        app.tables.staticTexts[editedName].swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertFalse(app.tables.staticTexts[editedName].waitForExistence(timeout: 2),
                       "Deleted item should be gone from the list")
    }

    @MainActor
    func testPokeymonListAccessibility() throws {
        // The list starts empty, so add one Pokeymon to have something to audit
        addPokeymon(named: "Potato", attackIncrements: 1, defenseIncrements: 1)
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 5))

        // This may fail - the audit report is what we want to look at
        try app.performAccessibilityAudit()
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
