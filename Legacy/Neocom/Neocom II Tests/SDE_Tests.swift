//
//  SDE_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 21.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import Neocom
import Expressible
import CoreData


class SDE_Tests: TestCase {
	
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
	
	func testIcons() {
		let context = Services.sde.viewContext
		
		XCTAssertNotNil(context.eveIcon(.defaultCategory)?.image?.image)
		XCTAssertNotNil(context.eveIcon(.defaultGroup)?.image?.image)
		XCTAssertNotNil(context.eveIcon(.defaultType)?.image?.image)
		for level in 0...4 {
			XCTAssertNotNil(context.eveIcon(.mastery(level))?.image?.image)
		}
		XCTAssertNotNil(context.eveIcon(.mastery(nil))?.image?.image)
	}
	
	func testTypes() {
		let context = Services.sde.viewContext
		let a = context.invType(645)
		let b = context.invType("dominix")
		XCTAssertNotNil(a)
		XCTAssertNotNil(b)
		XCTAssertEqual(a, b)
		try! XCTAssertTrue(context.managedObjectContext
			.from(SDEInvType.self)
			.filter(\SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue)
			.count() > 0)
		
	}
	
	func testLocationPicker() {
		let controller = try! MapLocationPicker.default.instantiate(MapLocationPicker.View.Input(mode: [.regions], completion: { (_, _) in
		})).get()
		
		
		controller.loadViewIfNeeded()
		controller.topViewController?.loadViewIfNeeded()
		controller.viewWillAppear(false)
		controller.viewDidAppear(false)
		let regions = controller.topViewController?.children.first {$0 is MapLocationPickerRegionsViewController} as! MapLocationPickerRegionsViewController

//		let recent = controller.topViewController?.childViewControllers.first {$0 is MapLocationPickerRecentsViewController} as? MapLocationPickerRecentsViewController

		let exp = expectation(description: "end")
		
		DispatchQueue.main.async {
			self.add(controller.screenshot())
//			self.add(recent.screenshot())
			
			XCTAssertGreaterThan(regions.tableView.numberOfSections, 0)
			XCTAssertGreaterThan(regions.tableView.numberOfRows(inSection: 0), 0)
			
			exp.fulfill()
		}
		
		
		wait(for: [exp], timeout: 10)
	}
	
	func testInvCategories() {
		let controller = try! InvCategories.default.instantiate().get()
		wait(for: [test(controller)], timeout: 10)
	}
	
	func testInvGroups() {
		let ship = Services.sde.viewContext.invCategory(Int(SDECategoryID.ship.rawValue))
		let controller = try! InvGroups.default.instantiate(.category(ship!)).get()
		wait(for: [test(controller)], timeout: 10)
	}
	
	func testInvTypes() {
		func run (_ input: InvTypes.View.Input) -> XCTestExpectation {
			let controller = try! InvTypes.default.instantiate(input).get()
			return self.test(controller)
		}
		
		let group = Services.sde.viewContext.invCategory(Int(SDECategoryID.ship.rawValue))?.groups?.anyObject() as? SDEInvGroup
		let marketGroup = Services.sde.viewContext.invType("Dominix")!.marketGroup
		let npcGroup = Services.sde.viewContext.invType("Gist Seraphim")!.group?.npcGroups?.anyObject() as? SDENpcGroup
		
		let exp = [run(.group(group!)),
				   run(.marketGroup(marketGroup!)),
				   run(.npcGroup(npcGroup!))]

		wait(for: exp, timeout: 10)
	}
	
	func testMarketOrders() {
		let controller = try! InvTypeMarketOrders.default.instantiate(InvTypeMarketOrders.View.Input.typeID(645)).get()
		wait(for: [test(controller)], timeout: 10)
	}
	
	func testWH() {
		let controller = try! WhTypes.default.instantiate().get()
		wait(for: [test(controller)], timeout: 10)
	}
	
	func testNPC() {
		let controller = try! NpcGroups.default.instantiate().get()
		wait(for: [test(controller)], timeout: 10)
	}
	
	func testIncursions() {
		let controller = try! Incursions.default.instantiate().get()
		wait(for: [test(controller)], timeout: 10)
	}

}
