//
//  PokedexTestTests.swift
//  PokedexTestTests
//
//  Created by Kaushik Manian on 20/10/25.
//

import UIKit
import XCTest
@testable import PokedexTest

@MainActor
final class PokedexTestTests: XCTestCase {

//    func testSomething() {
//        XCTAssertEqual(0, 0)
//    }
    
    func test_appDelegateLaunch_successful() {
        // ARRANGE
        let appDelegate = AppDelegate()
        
        // ACT
        let didLaunch = appDelegate.application(UIApplication.shared, didFinishLaunchingWithOptions: nil)
        
        // ASSERT
        XCTAssertTrue(didLaunch)
    }
}

final class ModelTests: XCTestCase {
    func test_model_pokeymonType_hasExpectedEmojiMapping_andAllCasesCount() {
        // ARRANGE: Expected count
        let expectedCount = 8
        
        // ASSERT: Count matches
        XCTAssertEqual(PokeymonType.allCases.count, expectedCount)
        
        // ARRANGE: Expected emoji mapping
        let map: [PokeymonType: String] = [
                    .fire: "🔥", .water: "💧", .earth: "🪨", .grass: "🌿",
                    .electric: "⚡️", .ice: "❄️", .flying: "🪽", .psychic: "🔮"
                ]
        
        // ASSERT: Each type has correct emoji
        for (type, expectedEmoji) in map {
            XCTAssertEqual(type.emoji, expectedEmoji)
        }
    }
}

// TODO: Investigate why we had to put Pokeymon as a nonisolated class for this test to run
final class ModelInitTests: XCTestCase {
    func test_model_pokeymonInit_setsFields() {
        // ARRANGE
        let fixed = Date(timeIntervalSince1970: 1_700_000_000)
        
        // ACT - initialise a pokeymon
        let p = Pokeymon(name: "Pika", type: .electric, attack: 123, defense: 77, dateCaptured: fixed)
        
        // ASSERT
        XCTAssertEqual(p.name, "Pika")
        XCTAssertEqual(p.type, .electric)
        XCTAssertEqual(p.attack, 123)
        XCTAssertEqual(p.defense, 77)
        XCTAssertEqual(p.dateCaptured, fixed)
    }
}

@MainActor
final class CellTests: XCTestCase {
    func test_cellInitialState_hasDisclosureIndicator() {
        // ARRANGE
        let cell = PokeymonTableViewCell(
            style: .default, reuseIdentifier: PokeymonTableViewCell.identifier
        )
        
        // ACT - do nothing
        
        // ASSERT
        XCTAssertEqual(cell.accessoryType, .disclosureIndicator)
    }
}

@MainActor
final class CellConfigureTests: XCTestCase {
    func test_cellConfigure_setsAllVisibleTexts() {
        // ARRANGE
        let cell = PokeymonTableViewCell(
            style: .default,
            reuseIdentifier: PokeymonTableViewCell.identifier
        )
        let fixed = Date(timeIntervalSince1970: 1_700_000_000)
        let p = Pokeymon(
            name: "Charmy",
            type: .fire,
            attack: 250,
            defense: 199,
            dateCaptured: fixed
        )

        // ACT
        cell.configure(with: p)

        // ASSERT: Collect all label texts
        let labels = cell.contentView.allLabels()
        let texts = labels.compactMap { $0.text }

        XCTAssertTrue(texts.contains("Charmy"))
        XCTAssertTrue(texts.contains { $0.contains("🔥") && $0.contains("Fire") })
        XCTAssertTrue(texts.contains("⚔️ 250"))
        XCTAssertTrue(texts.contains("🛡️ 199"))
        XCTAssertTrue(texts.contains { $0.hasPrefix("📅 ") && $0.count > 3 })

        if let dateLabel = labels.first(where: { ($0.text ?? "").hasPrefix("📅 ") }) {
            XCTAssertEqual(dateLabel.textColor, .tertiaryLabel)
        }
    }
}

@MainActor
final class ListVCTests: XCTestCase {
    func test_listVC_hasTitle_andPresentsFormWhenAddTapped() {
        // ARRANGE
        let sut = ListViewController()
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav

        // ACT
        sut.loadViewIfNeeded()

        // ASSERT: Title
        XCTAssertEqual(sut.title, "Pokeymon Collection")

        // ACT: Tap add button
        let add = sut.navigationItem.rightBarButtonItem
        XCTAssertNotNil(add)
        _ = add?.target?.perform(add!.action!, with: add)

        // ASSERT: Form presented
        XCTAssertTrue(sut.presentedViewController is UINavigationController)
        let presentedNav = sut.presentedViewController as? UINavigationController
        XCTAssertTrue(presentedNav?.viewControllers.first is PokeymonFormViewController)

        // Cleanup
        sut.dismiss(animated: false)
        window.isHidden = true
    }
}

@MainActor
final class ListVCAddTests: XCTestCase {
    func test_listVC_didAddPokeymon_updatesTableRowCount() {
        // ARRANGE
        let sut = ListViewController()
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav
        sut.loadViewIfNeeded()

        let table = sut.view.firstSubview(of: UITableView.self)!
        XCTAssertEqual(sut.tableView(table, numberOfRowsInSection: 0), 0)

        // ACT
        sut.didAddPokeymon(.init(name: "Bulby", type: .grass, attack: 10, defense: 20))

        // ASSERT
        XCTAssertEqual(sut.tableView(table, numberOfRowsInSection: 0), 1)
        window.isHidden = true
    }
}

@MainActor
final class ListVCSelectTests: XCTestCase {
    func test_listVC_didSelectRow_pushesDetailWithSameModel() {
        // ARRANGE
        let sut = ListViewController()
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav
        sut.loadViewIfNeeded()

        let table = sut.view.firstSubview(of: UITableView.self)!
        let p = Pokeymon(name: "Misty", type: .water, attack: 42, defense: 24)
        sut.didAddPokeymon(p)

        // ACT
        sut.tableView(table, didSelectRowAt: IndexPath(row: 0, section: 0))

        // ASSERT
        XCTAssertTrue(nav.topViewController is PokeymonDetailViewController)
        let detail = nav.topViewController as! PokeymonDetailViewController
        let cell = detail.tableView(detail.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(cell.detailTextLabel?.text, "Misty")
        window.isHidden = true
    }
}

@MainActor
final class ListVCDeleteTests: XCTestCase {
    func test_listVC_deleteRow_removesItem_andRowCountDecreases() {
        // ARRANGE
        let sut = ListViewController()
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav
        sut.loadViewIfNeeded()

        let table = sut.view.firstSubview(of: UITableView.self)!
        sut.didAddPokeymon(.init(name: "A", type: .fire, attack: 1, defense: 1))
        sut.didAddPokeymon(.init(name: "B", type: .water, attack: 2, defense: 2))
        XCTAssertEqual(sut.tableView(table, numberOfRowsInSection: 0), 2)

        // ACT
        sut.tableView(table, commit: .delete, forRowAt: IndexPath(row: 0, section: 0))

        // ASSERT
        XCTAssertEqual(sut.tableView(table, numberOfRowsInSection: 0), 1)
        window.isHidden = true
    }
}

@MainActor
final class ListVCRowsTests: XCTestCase {
    func test_listVC_rowHeights_matchContract() {
        // ARRANGE
        let sut = ListViewController()
        sut.loadViewIfNeeded()
        let table = sut.view.firstSubview(of: UITableView.self)!

        // ACT & ASSERT
        XCTAssertEqual(sut.tableView(table, heightForRowAt: IndexPath(row: 0, section: 0)), UITableView.automaticDimension)
        XCTAssertEqual(sut.tableView(table, estimatedHeightForRowAt: IndexPath(row: 0, section: 0)), 100)
    }
}

@MainActor
final class DetailVCTests: XCTestCase {
    func test_detailVC_hasTitle() {
        // ARRANGE
        let sut = PokeymonDetailViewController(pokeymon: Pokeymon.makeTest())
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav
        // ACT
        sut.loadViewIfNeeded()

        // ASSERT
        XCTAssertEqual(sut.title, "Details")
    }

    func test_detailVC_hasSectionHeaders() {
        // ARRANGE
        let sut = PokeymonDetailViewController(pokeymon: Pokeymon.makeTest())
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav

        // ACT
        sut.loadViewIfNeeded()

        // ASSERT
        XCTAssertEqual(sut.tableView(sut.tableView, titleForHeaderInSection: 0), "Information")
        XCTAssertEqual(sut.tableView(sut.tableView, titleForHeaderInSection: 1), "Stats")
    }

    func test_detailVC_statsCells_showEmojiLabels_statValues_andColors() {
        // ARRANGE
        let fixed_attack = 250
        let fixed_defense = 199
        let sut = PokeymonDetailViewController(pokeymon: Pokeymon.makeTest(attack: fixed_attack, defense: fixed_defense))
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav
        
        // ACT
        sut.loadViewIfNeeded()
        let attackCell = sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 0, section: 1))
        let defenseCell = sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 1, section: 1))

        // ASSERT
        XCTAssertEqual(attackCell.textLabel?.text, "⚔️ Attack")
        XCTAssertEqual(attackCell.detailTextLabel?.text, "\(fixed_attack)")
        XCTAssertEqual(attackCell.detailTextLabel?.textColor, .systemRed)

        XCTAssertEqual(defenseCell.textLabel?.text, "🛡️ Defence")
        XCTAssertEqual(defenseCell.detailTextLabel?.text, "\(fixed_defense)")
        XCTAssertEqual(defenseCell.detailTextLabel?.textColor, .systemBlue)
    }

    func test_detailVC_editPresentsFormWithSameModel_andCancelDoesNotTriggerDelegates() {
        // ARRANGE
        let p = Pokeymon.makeTest(name: "Edit Me")
        let sut = PokeymonDetailViewController(pokeymon: p)
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav

        // ACT - tap edit
        sut.loadViewIfNeeded()
        let edit = sut.navigationItem.rightBarButtonItem
        XCTAssertNotNil(edit)
        _ = edit?.target?.perform(edit!.action!, with: edit)

        // ASSERT - check if edit form shows up and has the pokeymon data
        let presentedNav = sut.presentedViewController as? UINavigationController
        let form = presentedNav?.viewControllers.first as? PokeymonFormViewController
        XCTAssertNotNil(form)
        XCTAssertTrue(form?.pokeymon === p)

        // ARRANGE - swap in a spy delegate to not trigger the real ones
        let spy = FormDelegateSpy()
        form?.delegate = spy

        // ACT - tap cancel to dismiss window
        form?.loadViewIfNeeded()
        let cancel = form?.navigationItem.leftBarButtonItem
        XCTAssertNotNil(cancel)
        _ = cancel?.target?.perform(cancel!.action!, with: cancel)
        
        // ASSERT - dismissed, so no delegate calls to update pokeymon
        let dismissedPredicate = NSPredicate(format: "presentedViewController == nil")
        let expectation = XCTNSPredicateExpectation(predicate: dismissedPredicate, object: sut)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5.0)
        XCTAssertNil(spy.updated)
        XCTAssertEqual(result, .completed) // TODO: Check if this expectation is proper
    }
    
    func test_detailVC_editPresentsFormWithSameModel_andSaveTriggerDelegateWithValues() {
        // ARRANGE
        let p = Pokeymon.makeTest(name: "Edit Me")
        let sut = PokeymonDetailViewController(pokeymon: p)
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav

        // ACT - tap edit
        sut.loadViewIfNeeded()
        let edit = sut.navigationItem.rightBarButtonItem
        XCTAssertNotNil(edit)
        _ = edit?.target?.perform(edit!.action!, with: edit)

        // ASSERT - check if edit form shows up and has the pokeymon data
        let presentedNav = sut.presentedViewController as? UINavigationController
        let form = presentedNav?.viewControllers.first as? PokeymonFormViewController
        XCTAssertNotNil(form)
        XCTAssertTrue(form?.pokeymon === p)

        // ARRANGE - swap in a spy delegate to not trigger the real ones
        let spy = FormDelegateSpy()
        form?.delegate = spy

        // ACT - tap save to save the same model
        form?.loadViewIfNeeded()
        let save = form?.navigationItem.rightBarButtonItem
        XCTAssertNotNil(save)
        _ = save?.target?.perform(save!.action!, with: save)
        
        // ASSERT - saved and shd be the same object
        XCTAssertTrue(spy.updated === p)
    }
}

@MainActor
final class FormVCTests: XCTestCase {
    func test_addForm_presents_haveSections() {
        // ARRANGE
        let sut = PokeymonFormViewController()
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav
        
        // ACT
        sut.loadViewIfNeeded()
        
        // ASSERT
        XCTAssertEqual(sut.tableView(sut.tableView, titleForHeaderInSection: 0), "Basic Info")
        XCTAssertEqual(sut.tableView(sut.tableView, titleForHeaderInSection: 1), "Type")
        XCTAssertEqual(sut.tableView(sut.tableView, titleForHeaderInSection: 2), "Stats")
        XCTAssertEqual(sut.tableView(sut.tableView, titleForHeaderInSection: 3), "Date Captured")
    }
    
    func test_addForm_sectionsHaveRowCounts() {
        // ARRANGE
        let sut = PokeymonFormViewController()
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav
        let rowCounts = [1, 1, 2, 1] // basic info, type, stats, date captured
        
        // ACT
        sut.loadViewIfNeeded()
        
        // ASSERT
        XCTAssertEqual(sut.numberOfSections(in: sut.tableView), rowCounts.count)
        for (section, rows) in rowCounts.enumerated() {
            XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: section), rows)
        }
    }
    
    func test_addForm_rowHeights_matchContract() {
        // ARRANGE
        let sut = PokeymonFormViewController()
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav
        let rowCounts = [1, 1, 2, 1] // basic info, type, stats, date captured
        let expectedHeights: [CGFloat] = [
            UITableView.automaticDimension, // basic info
            200,                            // type picker
            UITableView.automaticDimension, // stats
            200                             // date picker
        ]
        
        // ACT
        sut.loadViewIfNeeded()
        
        // ASSERT
        for (section, rows) in rowCounts.enumerated() {
            XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: section), rows)
            for row in 0..<rows {
                let indexPath = IndexPath(row: row, section: section)
                XCTAssertEqual(sut.tableView(sut.tableView, heightForRowAt: indexPath), expectedHeights[section])
            }
        }
    }
    
    func test_addForm_saveNewItem_triggersDidAddOnListDelegate() {
        // ARRANGE - real delegate is the list VC
        let list = ListViewController()
        let table = list.view.firstSubview(of: UITableView.self)!
        let sut = PokeymonFormViewController()
        sut.delegate = list
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav
        let p = Pokeymon.makeTest(name: "Pika", type: .electric, attack: 250, defense: 199)
        
        // ACT - populate fields
        list.loadViewIfNeeded()
        sut.loadViewIfNeeded()
        let nameCell = sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        nameCell.contentView.firstSubview(of: UITextField.self)?.text = p.name
        let typeCell = sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 0, section: 1))
        let typeIndex = PokeymonType.allCases.firstIndex(of: p.type)!
        typeCell.contentView.firstSubview(of: UIPickerView.self)?.selectRow(typeIndex, inComponent: 0, animated: false)
        let attackCell = sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 0, section: 2))
        (attackCell.accessoryView as? UIStepper)?.value = Double(p.attack)
        let defenseCell = sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 1, section: 2))
        (defenseCell.accessoryView as? UIStepper)?.value = Double(p.defense)
        
        // ACT - tap save
        let save = sut.navigationItem.rightBarButtonItem
        XCTAssertNotNil(save)
        _ = save?.target?.perform(save!.action!, with: save)
        
        // ASSERT - and the real list VC still handled it
        XCTAssertEqual(list.tableView(table, numberOfRowsInSection: 0), 1)
    }
    
    func test_addForm_saveEmptyName_errorShown() {
        // ARRANGE
        let root = UIViewController()
        let window = makeKeyTestWindow()
        window.rootViewController = root
        let sut = PokeymonFormViewController()
        let nav = UINavigationController(rootViewController: sut)
        root.present(nav, animated: false)
        sut.loadViewIfNeeded()
        
        // ACT - tap save without entering a name
        let save = sut.navigationItem.rightBarButtonItem
        XCTAssertNotNil(save)
        _ = save?.target?.perform(save!.action!, with: save)
        
        // ASSERT - error alert shown, form not dismissed
        let alert = nav.presentedViewController as? UIAlertController
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert?.title, "Error")
        XCTAssertEqual(alert?.message, "Please enter a name for your Pokeymon")
        XCTAssertTrue(root.presentedViewController === nav)
        XCTAssertFalse(nav.isBeingDismissed)
    }
    
    func test_addForm_steppersChanged_updateValuesInCells() {
        // ARRANGE
        let sut = PokeymonFormViewController()
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav
        sut.loadViewIfNeeded()
        sut.tableView.reloadData()
        sut.tableView.layoutIfNeeded()
        let attackIndex = IndexPath(row: 0, section: 2)
        let defenseIndex = IndexPath(row: 1, section: 2)
        
        // ACT - change the steppers like a user would
        let attackStepper = sut.tableView.cellForRow(at: attackIndex)?.accessoryView as? UIStepper
        let defenseStepper = sut.tableView.cellForRow(at: defenseIndex)?.accessoryView as? UIStepper
        XCTAssertNotNil(attackStepper)
        XCTAssertNotNil(defenseStepper)
        attackStepper?.value = 42
        attackStepper?.sendActions(for: .valueChanged)
        defenseStepper?.value = 17
        defenseStepper?.sendActions(for: .valueChanged)
        
        // ASSERT - the visible cells updated
        XCTAssertEqual(sut.tableView.cellForRow(at: attackIndex)?.detailTextLabel?.text, "42")
        XCTAssertEqual(sut.tableView.cellForRow(at: defenseIndex)?.detailTextLabel?.text, "17")
        
        // ASSERT - and the internal state did too (a freshly built cell reads from it)
        XCTAssertEqual(sut.tableView(sut.tableView, cellForRowAt: attackIndex).detailTextLabel?.text, "42")
        XCTAssertEqual(sut.tableView(sut.tableView, cellForRowAt: defenseIndex).detailTextLabel?.text, "17")
    }
    
    func test_addForm_picker_listsAllTypesWithEmojiAndName() {
        // ARRANGE
        let sut = PokeymonFormViewController()
        let nav = UINavigationController(rootViewController: sut)
        let window = makeKeyTestWindow()
        window.rootViewController = nav
        
        // ACT
        sut.loadViewIfNeeded()
        let typeCell = sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 0, section: 1))
        let picker = typeCell.contentView.firstSubview(of: UIPickerView.self)
        XCTAssertNotNil(picker)
        
        // ASSERT
        XCTAssertEqual(sut.numberOfComponents(in: picker!), 1)
        XCTAssertEqual(sut.pickerView(picker!, numberOfRowsInComponent: 0), PokeymonType.allCases.count)
        for (row, type) in PokeymonType.allCases.enumerated() {
            XCTAssertEqual(
                sut.pickerView(picker!, titleForRow: row, forComponent: 0),
                "\(type.emoji) \(type.rawValue.capitalized)"
            )
        }
    }

}

// MARK: - Test-only helpers

@MainActor
@discardableResult
private func makeKeyTestWindow() -> UIWindow {
    let scene = UIApplication.shared.connectedScenes.first as! UIWindowScene
    let w = UIWindow(windowScene: scene)
    w.frame = scene.screen.bounds
    w.makeKeyAndVisible()
    return w
}

private extension Pokeymon {
    static func makeTest(
        name: String = "TestMon",
        type: PokeymonType = .fire,
        attack: Int = 100,
        defense: Int = 100,
        dateCaptured: Date = Date()
    ) -> Pokeymon {
        .init(name: name, type: type, attack: attack, defense: defense, dateCaptured: dateCaptured)
    }
}

private extension UIView {
    /// Depth-first search for first subview of type
    func firstSubview<T: UIView>(of type: T.Type) -> T? {
        if let v = self as? T { return v }
        for s in subviews {
            if let v: T = s.firstSubview(of: type) { return v }
        }
        return nil
    }

    /// Collect all labels under this view
    func allLabels() -> [UILabel] {
        var out: [UILabel] = []
        if let l = self as? UILabel { out.append(l) }
        for s in subviews { out.append(contentsOf: s.allLabels()) }
        return out
    }
}

@MainActor
private final class FormDelegateSpy: PokeymonFormViewControllerDelegate {
    private(set) var added: Pokeymon?
    private(set) var updated: Pokeymon?

    func didAddPokeymon(_ pokeymon: Pokeymon) {
        added = pokeymon
    }

    func didUpdatePokeymon(_ pokeymon: Pokeymon) {
        updated = pokeymon
    }
}
