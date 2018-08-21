//
//  Neocom_II_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 01.03.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
import CoreData
@testable import Neocom

let sde = SDEPersistentContainer()

class Neocom_II_Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
	
	
	
	/*func testDgmppItemCategories() {
		(try! NCDatabase.sharedDatabase!.viewContext.fetch(NSFetchRequest<NCDBDgmppItemCategory>(entityName: "DgmppItemCategory"))).forEach { category in
			func items(_ group: NCDBDgmppItemGroup) -> [NCDBDgmppItem] {
				var result = group.items?.allObjects as? [NCDBDgmppItem] ?? []
				result.append(contentsOf: (group.subGroups?.allObjects as? [NCDBDgmppItemGroup] ?? []).map {items($0)}.joined())
				return result
			}
			let a = (category.itemGroups!.allObjects as! [NCDBDgmppItemGroup]).map {items($0)}.joined()
//			let item: NCDBDgmppItem? = a.count <= 0 ? NCDatabase.sharedDatabase!.viewContext.fetch("DgmppItem", where: "charge == %@", category) : nil
			XCTAssertGreaterThan(a.count, 0, "[\(NCDBDgmppItemCategoryID(rawValue: Int(category.category))!), \(category.subcategory)], items:\((category.dgmppItems as? Set<NCDBDgmppItem>)?.compactMap {$0.type?.typeName} ?? []), groups: \((category.itemGroups as? Set<NCDBDgmppItemGroup>)?.compactMap {$0.groupName} ?? [])")
		}
		
		
		let categories = [
			NCDBDgmppItemCategory.category(categoryID: .ship)!,
			NCDBDgmppItemCategory.category(categoryID: .structure)!,
			NCDBDgmppItemCategory.category(categoryID: .hi, subcategory: NCDBCategoryID.structureModule.rawValue)!,
			NCDBDgmppItemCategory.category(categoryID: .hi, subcategory: NCDBCategoryID.module.rawValue)!,
			NCDBDgmppItemCategory.category(categoryID: .med, subcategory: NCDBCategoryID.structureModule.rawValue)!,
			NCDBDgmppItemCategory.category(categoryID: .med, subcategory: NCDBCategoryID.module.rawValue)!,
			NCDBDgmppItemCategory.category(categoryID: .low, subcategory: NCDBCategoryID.structureModule.rawValue)!,
			NCDBDgmppItemCategory.category(categoryID: .low, subcategory: NCDBCategoryID.module.rawValue)!,
			NCDBDgmppItemCategory.category(categoryID: .structureRig, subcategory: 2)!,
			NCDBDgmppItemCategory.category(categoryID: .rig, subcategory: 1)!,
			NCDBDgmppItemCategory.category(categoryID: .subsystem, subcategory: nil, race: NCDatabase.sharedDatabase!.chrRaces[1]!)!,
		]
		for category in categories {
			func items(_ group: NCDBDgmppItemGroup) -> [NCDBDgmppItem] {
				var result = group.items?.allObjects as? [NCDBDgmppItem] ?? []
				result.append(contentsOf: (group.subGroups?.allObjects as? [NCDBDgmppItemGroup] ?? []).map {items($0)}.joined())
				return result
			}
			let a = (category.itemGroups!.allObjects as! [NCDBDgmppItemGroup]).map {items($0)}.joined()
			XCTAssertGreaterThan(a.count, 0, "\(category)")
		}
	}*/
    
}
