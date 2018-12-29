//
//  Fitting_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 11/26/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import Neocom
import Expressible

class Fitting_Tests: TestCase {
	
	static let lock: NSLock = {
		return NSLock()
	}()

    override func setUp() {
		super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
	
	func testFittingMenu() {
		let controller = try! FittingMenu.default.instantiate().get()
		controller.loadViewIfNeeded()
		add(controller.screenshot())
	}

    func testShipLoadouts() {
		Fitting_Tests.lock.lock(); defer {Fitting_Tests.lock.unlock()}
		let context = Services.storage.viewContext.managedObjectContext
		try! context.from(Fleet.self).delete()
		try! context.from(Loadout.self).delete()
		try! context.save()

		var loadout = Loadout(context: context)
		loadout.name = "Test Loadout 1"
		loadout.typeID = 645
		loadout.uuid = "1"
		loadout.data = LoadoutData(context: context)
		try! context.save()

		let controller = try! FittingLoadouts.default.instantiate(.ship).get()
		wait(for: [test(controller)], timeout: 10)
		
		loadout.name = "Test Loadout 1 Renamed"
		
		loadout = Loadout(context: context)
		loadout.name = "Test Loadout 2"
		loadout.typeID = 645
		loadout.uuid = "2"
		loadout.data = LoadoutData(context: context)
		try! context.save()
		
		let exp = expectation(description: "end")
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			self.add(controller.screenshot())
			
			XCTAssertEqual(controller.tableView.numberOfSections, 2)
			XCTAssertEqual(controller.tableView.numberOfRows(inSection: 1), 3)
			
			XCTAssertEqual((controller.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) as? TreeDefaultCell)?.subtitleLabel?.text, "Test Loadout 1 Renamed")

			try? context.from(Loadout.self).fetch().forEach {context.delete($0)}
			try! context.save()

			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				self.add(controller.screenshot())
				XCTAssertEqual(controller.tableView.numberOfSections, 2)
				XCTAssertEqual(controller.tableView.numberOfRows(inSection: 1), 0)
				
				loadout = Loadout(context: context)
				loadout.name = "Test Loadout 3"
				loadout.typeID = 645
				loadout.uuid = "3"
				loadout.data = LoadoutData(context: context)
				
				try! context.save()

				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					
					loadout = Loadout(context: context)
					loadout.name = "Test Loadout 4"
					loadout.typeID = Services.sde.viewContext.invType("Deimos")!.typeID
					loadout.uuid = "4"
					loadout.data = LoadoutData(context: context)

					loadout = Loadout(context: context)
					loadout.name = "Test Loadout 5"
					loadout.typeID = Services.sde.viewContext.invType("Ishkur")!.typeID
					loadout.uuid = "5"
					loadout.data = LoadoutData(context: context)

					try! context.save()
					XCTAssertEqual(controller.tableView.numberOfSections, 2)

					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
						self.add(controller.screenshot())

						XCTAssertEqual(controller.tableView.numberOfSections, 2)
						XCTAssertEqual(controller.tableView.numberOfRows(inSection: 1), 6)
						exp.fulfill()
					}
				}
			}

		}
		wait(for: [exp], timeout: 10)
    }
	
	func testStructureLoadouts() {
		Fitting_Tests.lock.lock(); defer {Fitting_Tests.lock.unlock()}
		let context = Services.storage.viewContext.managedObjectContext
		let loadout = Loadout(context: context)
		
		loadout.name = "Test Loadout 1"
		loadout.typeID = Services.sde.viewContext.invType("Fortizar")!.typeID
		loadout.uuid = "s1"
		loadout.data = LoadoutData(context: context)
		try! context.save()
		
		let controller = try! FittingLoadouts.default.instantiate(.structure).get()
		wait(for: [test(controller)], timeout: 10)
	}
	
	func testFleets() {
		Fitting_Tests.lock.lock(); defer {Fitting_Tests.lock.unlock()}
		let context = Services.storage.viewContext.managedObjectContext
		try! context.from(Fleet.self).delete()
		
		let fleet = Fleet(context: context)
		fleet.name = "Test Fleet"
		
		let loadout1 = Loadout(context: context)
		loadout1.name = "Test Loadout 1"
		loadout1.typeID = Services.sde.viewContext.invType("Deimos")!.typeID
		loadout1.uuid = "1"
		loadout1.data = LoadoutData(context: context)
		loadout1.addToFleets(fleet)

		let loadout2 = Loadout(context: context)
		loadout2.name = "Test Loadout 2"
		loadout2.typeID = Services.sde.viewContext.invType("Dominix")!.typeID
		loadout2.uuid = "2"
		loadout2.data = LoadoutData(context: context)
		loadout2.addToFleets(fleet)

		try! context.save()
		
		let controller = try! FittingFleets.default.instantiate().get()
		wait(for: [test(controller)], timeout: 10)

	}
	
	func testTypePicker() {
		let category = Services.sde.viewContext.dgmppItemCategory(categoryID: .ship)!
		
		let navigationController = try! DgmTypePicker.default.instantiate(DgmTypePicker.View.Input(category: category, completion: {_,_ in})).get()
		navigationController.loadViewIfNeeded()
		navigationController.topViewController?.loadViewIfNeeded()
		let controller = navigationController.topViewController!.children[0] as! DgmTypePickerGroupsViewController

		wait(for: [test(controller, takeScreenshot: false)], timeout: 10)
		add(navigationController.screenshot())
	}

	func testTypePickerTypes() {
		let category = Services.sde.viewContext.dgmppItemCategory(categoryID: .ship)!
		
		let group = sequence(first: (category.itemGroups!.anyObject() as! SDEDgmppItemGroup), next: {$0.subGroups?.anyObject() as? SDEDgmppItemGroup}).reversed().first!

		let controller = try! DgmTypePickerTypes.default.instantiate(.group(group)).get()
		
		wait(for: [test(controller)], timeout: 10)
	}

	func testTypePickerSearch() {
		let category = Services.sde.viewContext.dgmppItemCategory(categoryID: .ship)!
		
		let controller = try! DgmTypePickerTypes.default.instantiate(.category(category)).get()
		let searchController = UISearchController(searchResultsController: controller)
		searchController.loadViewIfNeeded()
		controller.presenter.updateSearchResults(with: "Dominix")
		wait(for: [test(controller, takeScreenshot: false)], timeout: 10)
		controller.removeFromParent()
		add(controller.screenshot())
	}
	
	func testTypePickerRecents() {
		let category = Services.sde.viewContext.dgmppItemCategory(categoryID: .ship)!
		
		let group = sequence(first: (category.itemGroups!.anyObject() as! SDEDgmppItemGroup), next: {$0.subGroups?.anyObject() as? SDEDgmppItemGroup}).reversed().first!
		
		let controller = try! DgmTypePickerTypes.default.instantiate(.group(group)).get()
		controller.presenter.interactor.touch((group.items!.anyObject() as! SDEDgmppItem).type!)
		wait(for: [test(controller, takeScreenshot: false)], timeout: 10)
		
		let recents = try! DgmTypePickerRecents.default.instantiate(category).get()
		wait(for: [test(recents)], timeout: 10)
	}

}
