//
//  Neocom_II_Tests.swift
//  Neocom II Tests
//
//  Created by Artem Shimanski on 01.03.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
import CoreData
import EVEAPI
@testable import Neocom

let sde: SDE = SDEContainer()

let cache: Cache = {
	let container = NSPersistentContainer(name: "Cache", managedObjectModel: NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Cache", withExtension: "momd")!)!)
	let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Cache.sqlite")
	try? FileManager.default.removeItem(at: url)
	
	let description = NSPersistentStoreDescription()
	description.url = url
	container.persistentStoreDescriptions = [description]
	container.loadPersistentStores { (description, error) in
		XCTAssertNil(error)
	}
	return CacheContainer(persistentContainer: container)
}()

let storage: Storage = {
	let container = NSPersistentContainer(name: "Store", managedObjectModel: NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Storage", withExtension: "momd")!)!)
	let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("store.sqlite")
	try? FileManager.default.removeItem(at: url)
	
	let description = NSPersistentStoreDescription()
	description.url = url
	container.persistentStoreDescriptions = [description]
	container.loadPersistentStores { (description, error) in
		XCTAssertNil(error)
	}
	
	return StorageContainer(persistentContainer: container)
}()


let oAuth2Token = try! JSONDecoder().decode(OAuth2Token.self, from: "{\"scopes\":[\"esi-calendar.respond_calendar_events.v1\",\"esi-calendar.read_calendar_events.v1\",\"esi-location.read_location.v1\",\"esi-location.read_ship_type.v1\",\"esi-mail.organize_mail.v1\",\"esi-mail.read_mail.v1\",\"esi-mail.send_mail.v1\",\"esi-skills.read_skills.v1\",\"esi-skills.read_skillqueue.v1\",\"esi-wallet.read_character_wallet.v1\",\"esi-search.search_structures.v1\",\"esi-clones.read_clones.v1\",\"esi-universe.read_structures.v1\",\"esi-killmails.read_killmails.v1\",\"esi-assets.read_assets.v1\",\"esi-planets.manage_planets.v1\",\"esi-fittings.read_fittings.v1\",\"esi-fittings.write_fittings.v1\",\"esi-markets.structure_markets.v1\",\"esi-characters.read_loyalty.v1\",\"esi-characters.read_standings.v1\",\"esi-industry.read_character_jobs.v1\",\"esi-markets.read_character_orders.v1\",\"esi-characters.read_blueprints.v1\",\"esi-contracts.read_character_contracts.v1\",\"esi-clones.read_implants.v1\",\"esi-killmails.read_corporation_killmails.v1\",\"esi-wallet.read_corporation_wallets.v1\",\"esi-corporations.read_divisions.v1\",\"esi-assets.read_corporation_assets.v1\",\"esi-corporations.read_blueprints.v1\",\"esi-contracts.read_corporation_contracts.v1\",\"esi-industry.read_corporation_jobs.v1\",\"esi-markets.read_corporation_orders.v1\"],\"characterID\":1554561480,\"characterName\":\"Artem Valiant\",\"refreshToken\":\"1ETZtnu7-ic9k1vE-rhBGhC76QQ5VMCbzKU3bIid32BgS00pgtOJPozLGaUSociDGpnyzpPLMapm3bOvbjERA0wUYPvNMmr77HPdrJtFh09kII7VN5SxvaVKYO9PkokE4GByoWY8ExmiQadXLmy5yzzJx4BkvI4mobv82MG7LZzbil8n4rH23bSOnVQGOuzBAgZflvwAEqdKw1y8Gm8PAlnoDjnb_B0LM2bBrvYz7zY1\",\"tokenType\":\"Bearer\",\"expiresOn\":556720099.51404095,\"accessToken\":\"YWm0r6Z1svq2Jido_8zHQ5bIo6TE72CmvI-TR8-9_VLgZd6plowi6r9OzQyC4_DzIImjAbhyRGSMz3Hv_6Z6kg2\",\"realm\":\"esi\"}".data(using: .utf8)!)



/*class Neocom_II_Tests: XCTestCase {
    
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
*/
