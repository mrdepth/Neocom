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


class SDE_Tests: XCTestCase {
	
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
	func testIcons() {
		let context = sde.viewContext
		
		XCTAssertNotNil(context.eveIcon(.defaultCategory)?.image?.image)
		XCTAssertNotNil(context.eveIcon(.defaultGroup)?.image?.image)
		XCTAssertNotNil(context.eveIcon(.defaultType)?.image?.image)
		for level in 0...4 {
			XCTAssertNotNil(context.eveIcon(.mastery(level))?.image?.image)
		}
		XCTAssertNotNil(context.eveIcon(.mastery(nil))?.image?.image)
	}
	
	func testTypes() {
		let context = sde.viewContext
		let a = context.invType(645)
		let b = context.invType("dominix")
		XCTAssertNotNil(a)
		XCTAssertNotNil(b)
		XCTAssertEqual(a, b)
		try! XCTAssertTrue(context.managedObjectContext.from(SDEInvType.self).filter(\SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue).count() > 0)
		
	}
}
