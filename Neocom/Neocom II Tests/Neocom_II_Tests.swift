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
import UIKit
@testable import Neocom

/*let sde: SDE = SDEContainer()

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
}()*/


fileprivate let oAuth2Token = try! JSONDecoder().decode(OAuth2Token.self, from: "{\"scopes\":[\"esi-calendar.respond_calendar_events.v1\",\"esi-calendar.read_calendar_events.v1\",\"esi-location.read_location.v1\",\"esi-location.read_ship_type.v1\",\"esi-mail.organize_mail.v1\",\"esi-mail.read_mail.v1\",\"esi-mail.send_mail.v1\",\"esi-skills.read_skills.v1\",\"esi-skills.read_skillqueue.v1\",\"esi-wallet.read_character_wallet.v1\",\"esi-search.search_structures.v1\",\"esi-clones.read_clones.v1\",\"esi-universe.read_structures.v1\",\"esi-killmails.read_killmails.v1\",\"esi-assets.read_assets.v1\",\"esi-planets.manage_planets.v1\",\"esi-fittings.read_fittings.v1\",\"esi-fittings.write_fittings.v1\",\"esi-markets.structure_markets.v1\",\"esi-characters.read_loyalty.v1\",\"esi-characters.read_standings.v1\",\"esi-industry.read_character_jobs.v1\",\"esi-markets.read_character_orders.v1\",\"esi-characters.read_blueprints.v1\",\"esi-contracts.read_character_contracts.v1\",\"esi-clones.read_implants.v1\",\"esi-killmails.read_corporation_killmails.v1\",\"esi-wallet.read_corporation_wallets.v1\",\"esi-corporations.read_divisions.v1\",\"esi-assets.read_corporation_assets.v1\",\"esi-corporations.read_blueprints.v1\",\"esi-contracts.read_corporation_contracts.v1\",\"esi-industry.read_corporation_jobs.v1\",\"esi-markets.read_corporation_orders.v1\"],\"characterID\":1554561480,\"characterName\":\"Artem Valiant\",\"refreshToken\":\"1ETZtnu7-ic9k1vE-rhBGhC76QQ5VMCbzKU3bIid32BgS00pgtOJPozLGaUSociDGpnyzpPLMapm3bOvbjERA0wUYPvNMmr77HPdrJtFh09kII7VN5SxvaVKYO9PkokE4GByoWY8ExmiQadXLmy5yzzJx4BkvI4mobv82MG7LZzbil8n4rH23bSOnVQGOuzBAgZflvwAEqdKw1y8Gm8PAlnoDjnb_B0LM2bBrvYz7zY1\",\"tokenType\":\"Bearer\",\"expiresOn\":556720099.51404095,\"accessToken\":\"YWm0r6Z1svq2Jido_8zHQ5bIo6TE72CmvI-TR8-9_VLgZd6plowi6r9OzQyC4_DzIImjAbhyRGSMz3Hv_6Z6kg2\",\"realm\":\"esi\"}".data(using: .utf8)!)

extension UIViewController {
	func screenshot(size: Size = .iPhone6) -> UIImage {
		view.frame = CGRect(origin: .zero, size: size.size)
		view.layoutIfNeeded()
		
		UIGraphicsBeginImageContextWithOptions(view.frame.size, true, size.scale)
		view.drawHierarchy(in: view.frame, afterScreenUpdates: true)
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		XCTAssertNotNil(image)
		
		UIGraphicsEndImageContext()
		return image!
	}
}

class TestCase: XCTestCase {
	
	private static let setUpOnce: Void = {
		Services.userDefaults = UserDefaults()
		Services.cache = cache()
		Services.storage = storage()
		let account = Services.storage.viewContext.newAccount(with: oAuth2Token)
		try! Services.storage.viewContext.save()
		Services.storage.viewContext.setCurrentAccount(account)

	}()
	
	override func setUp() {
		_ = TestCase.setUpOnce
		super.setUp()
	}
	
	private class func cache() -> Cache {
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
	}

	private class func storage() -> Storage {
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
	}
	
	func test<T: TreeView>(_ view: T) -> XCTestExpectation where T: UIViewController {
		view.loadViewIfNeeded()
		let exp = expectation(description: "end")
		
		view.presenter.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { result in
			view.present(result, animated: true).then(on: .main) { _ in
				self.add(view.screenshot())
				
				XCTAssertGreaterThan(view.tableView.numberOfSections, 0)
				XCTAssertGreaterThan(view.tableView.numberOfRows(inSection: 0), 0)
				
				exp.fulfill()
			}
		}
		return exp
	}
}

extension XCTestCase {
	func add(_ image: UIImage, name: String? = nil) {
		let attachment = XCTAttachment(image: image)
		attachment.lifetime = .keepAlways
		attachment.name = name
		add(attachment)
	}
	
}

enum Size {
	case iPhone4
	case iPhone5
	case iPhone6
	case iPhone6Plus
	case iPhoneX
	
	var size: CGSize {
		switch self {
		case .iPhone4:
			return CGSize(width: 320, height: 480)
		case .iPhone5:
			return CGSize(width: 320, height: 568)
		case .iPhone6:
			return CGSize(width: 375, height: 667)
		case .iPhone6Plus:
			return CGSize(width: 414, height: 736)
		case .iPhoneX:
			return CGSize(width: 375, height: 812)
		}
	}
	
	var scale: CGFloat {
		switch self {
		case .iPhone4, .iPhone5, .iPhone6:
			return 2
		case .iPhone6Plus, .iPhoneX:
			return 3
		}
	}
}
