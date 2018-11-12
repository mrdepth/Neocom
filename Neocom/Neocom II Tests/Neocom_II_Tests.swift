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
import Futures
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
		Services.api = APIServiceMock()
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
	
	func test<T: TreeView>(_ view: T, takeScreenshot: Bool = true) -> XCTestExpectation where T: UIViewController {
		view.loadViewIfNeeded()
		let exp = expectation(description: "end")
		
		view.presenter.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { result in
			view.present(result, animated: true).then(on: .main) { _ in
				if takeScreenshot {
					self.add(view.screenshot())
				}
				
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

class APIServiceMock: APIService {
	
	func make(for account: Account?) -> API {
		let esi = ESI(token: account?.oAuth2Token, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey, server: .tranquility)
		return APIMock(esi: esi)
	}
	
	var current: API {
		return make(for: Services.storage.viewContext.currentAccount)
	}
	
	func performAuthorization(from controller: UIViewController) {
	}
}

class APIMock: APIClient {
	
	override func serverStatus(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Status.ServerStatus>> {
		let value = ESI.Status.ServerStatus(players: 0, serverVersion: "1", startTime: Date(), vip: false)
		return .init(ESI.Result(value: value, expires: Date(timeIntervalSinceNow: 60), metadata: nil))
	}
	
	override func openOrders(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Market.CharacterOrder]>> {
		return Services.sde.performBackgroundTask { context -> ESI.Result<[ESI.Market.CharacterOrder]> in
			let solarSystem = try! context.managedObjectContext.from(SDEMapSolarSystem.self).first()!
			let orders = [ESI.Market.CharacterOrder(duration: 3600 * 2, escrow: 1000, isBuyOrder: true, isCorporation: false, issued: Date.init(timeIntervalSinceNow: -3600), locationID: Int64(solarSystem.solarSystemID), minVolume: 1000, orderID: 1, price: 1000, range: ESI.Market.CharacterOrder.GetCharactersCharacterIDOrdersRange.solarsystem, regionID: Int(solarSystem.constellation!.region!.regionID), typeID: 645, volumeRemain: 50, volumeTotal: 10000),
						  ESI.Market.CharacterOrder(duration: 3600*3, escrow: 1000, isBuyOrder: false, isCorporation: false, issued: Date.init(timeIntervalSinceNow: -3600), locationID: Int64(solarSystem.solarSystemID), minVolume: 1000, orderID: 1, price: 1000, range: ESI.Market.CharacterOrder.GetCharactersCharacterIDOrdersRange.solarsystem, regionID: Int(solarSystem.constellation!.region!.regionID), typeID: 645, volumeRemain: 50, volumeTotal: 10000)]
			return ESI.Result(value: orders, expires: nil, metadata: nil)
		}
	}
	
	override func industryJobs(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Industry.Job]>> {
		return Services.sde.performBackgroundTask { context -> ESI.Result<[ESI.Industry.Job]> in
			let station = try! context.managedObjectContext.from(SDEStaStation.self).first()!
			let activities = try! context.managedObjectContext.from(SDERamActivity.self).all()
			let blueprint = context.invType("Dominix Blueprint")!
			let locationID = Int64(station.stationID)
			
			let jobs = [
				
				ESI.Industry.Job(activityID: Int(activities.first!.activityID), blueprintID: 1, blueprintLocationID: locationID, blueprintTypeID: Int(blueprint.typeID), completedCharacterID: nil, completedDate: nil, cost: 1000, duration: 3600 * 2, endDate: Date.init(timeIntervalSinceNow: 3600), facilityID: locationID, installerID: 0, jobID: 0, licensedRuns: 1, outputLocationID: locationID, pauseDate: nil, probability: 1, productTypeID: nil, runs: 1, startDate: Date.init(timeIntervalSinceNow: -3600), stationID: locationID, status: .active, successfulRuns: 1),
				
				ESI.Industry.Job(activityID: Int(activities.first!.activityID), blueprintID: 1, blueprintLocationID: locationID, blueprintTypeID: Int(blueprint.typeID), completedCharacterID: nil, completedDate: nil, cost: 1000, duration: 3600 * 23, endDate: Date.init(timeIntervalSinceNow: -3600), facilityID: locationID, installerID: 0, jobID: 1, licensedRuns: 10, outputLocationID: locationID, pauseDate: nil, probability: 1, productTypeID: nil, runs: 10, startDate: Date.init(timeIntervalSinceNow: -3600 * 24), stationID: locationID, status: .delivered, successfulRuns: 10)

			]
			
			return ESI.Result(value: jobs, expires: nil, metadata: nil)
		}
	}
	
	override func contracts(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Contract]>> {
		return Services.sde.performBackgroundTask { context -> ESI.Result<[ESI.Contracts.Contract]> in
			let characterID = try! Services.storage.performBackgroundTask {context in Int(context.currentAccount?.characterID ?? 0)}.get()
			
			let station = Int64((try! context.managedObjectContext.from(SDEStaStation.self).first()!).stationID)
			
			let contracts = [
				ESI.Contracts.Contract(acceptorID: characterID, assigneeID: characterID, availability: .personal, buyout: 1000, collateral: 40, contractID: 1, dateAccepted: nil, dateCompleted: nil, dateExpired: Date(timeIntervalSinceNow: 3600), dateIssued: Date(timeIntervalSinceNow: -3600 * 23), daysToComplete: 1, endLocationID: station, forCorporation: false, issuerCorporationID: 0, issuerID: characterID, price: 1000, reward: 100, startLocationID: station, status: .inProgress, title: "Test Contract 1", type: .courier, volume: 100),
				
				ESI.Contracts.Contract(acceptorID: characterID, assigneeID: characterID, availability: .personal, buyout: 10000, collateral: 40, contractID: 1, dateAccepted: Date(timeIntervalSinceNow: -3600), dateCompleted: Date(timeIntervalSinceNow: -3600/2), dateExpired: Date(timeIntervalSinceNow: 3600), dateIssued: Date.init(timeIntervalSinceNow: -3600 * 24 * 2), daysToComplete: 3, endLocationID: station, forCorporation: false, issuerCorporationID: 0, issuerID: characterID, price: 1000, reward: 100, startLocationID: station, status: .finished, title: "Test Contract 2", type: .auction, volume: 100)
			]
			return ESI.Result(value: contracts, expires: nil, metadata: nil)
		}
	}
	
	override func contractItems(contractID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Item]>> {
		let value = [ESI.Contracts.Item(isIncluded: true, isSingleton: false, quantity: 1, rawQuantity: 1, recordID: 1, typeID: 645),
					 ESI.Contracts.Item(isIncluded: false, isSingleton: false, quantity: 10, rawQuantity: 10, recordID: 2, typeID: 34)]
		return .init(ESI.Result(value: value, expires: nil, metadata: nil))

	}
	
	override func contractBids(contractID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Bid]>> {
		return Services.storage.performBackgroundTask {context -> ESI.Result<[ESI.Contracts.Bid]> in
			let characterID = Int(context.currentAccount?.characterID ?? 0)
			let value = [ESI.Contracts.Bid(amount: 100, bidID: 1, bidderID: characterID, dateBid: Date.init(timeIntervalSinceNow: -3600 * 24)),
						 ESI.Contracts.Bid(amount: 1000, bidID: 1, bidderID: characterID, dateBid: Date.init(timeIntervalSinceNow: -3600 * 12))]
			return ESI.Result(value: value, expires: nil, metadata: nil)
		}
	}
	
	override func walletJournal(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Wallet.WalletJournalItem]>> {
		let value = [
			ESI.Wallet.WalletJournalItem(amount: 1000, balance: 1000000, contextID: 1, contextIDType: .characterID, date: Date(timeIntervalSinceNow: -3600), localizedDescription: "Test Item 1", firstPartyID: nil, id: 1, reason: "Reason", refType: .agentDonation, secondPartyID: nil, tax: 10, taxReceiverID: nil),
			ESI.Wallet.WalletJournalItem(amount: 1000, balance: 1000000, contextID: 1, contextIDType: .characterID, date: Date(timeIntervalSinceNow: -3600 * 24), localizedDescription: "Test Item 1", firstPartyID: nil, id: 1, reason: "Reason", refType: .agentDonation, secondPartyID: nil, tax: 10, taxReceiverID: nil),
			ESI.Wallet.WalletJournalItem(amount: 1000, balance: 1000000, contextID: 1, contextIDType: .characterID, date: Date(timeIntervalSinceNow: -3600 * 25), localizedDescription: "Test Item 1", firstPartyID: nil, id: 1, reason: "Reason", refType: .agentDonation, secondPartyID: nil, tax: 10, taxReceiverID: nil),
			ESI.Wallet.WalletJournalItem(amount: 1000, balance: 1000000, contextID: 1, contextIDType: .characterID, date: Date(timeIntervalSinceNow: -3600 * 50), localizedDescription: "Test Item 1", firstPartyID: nil, id: 1, reason: "Reason", refType: .agentDonation, secondPartyID: nil, tax: 10, taxReceiverID: nil)]
		return .init(ESI.Result(value: value, expires: nil, metadata: nil))
	}
	
	override func walletTransactions(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Wallet.Transaction]>> {
		return Services.sde.performBackgroundTask { context -> ESI.Result<[ESI.Wallet.Transaction]> in
			let characterID = try! Services.storage.performBackgroundTask {context in Int(context.currentAccount?.characterID ?? 0)}.get()
			let station = Int64((try! context.managedObjectContext.from(SDEStaStation.self).first()!).stationID)

			let value = [ESI.Wallet.Transaction(clientID: characterID, date: Date(timeIntervalSinceNow: -3600), isBuy: true, isPersonal: true, journalRefID: 1, locationID: station, quantity: 1, transactionID: 1, typeID: 645, unitPrice: 100),
						 ESI.Wallet.Transaction(clientID: characterID, date: Date(timeIntervalSinceNow: -3600 * 12), isBuy: true, isPersonal: true, journalRefID: 1, locationID: station, quantity: 1, transactionID: 1, typeID: 645, unitPrice: 100),
						 ESI.Wallet.Transaction(clientID: characterID, date: Date(timeIntervalSinceNow: -3600 * 24), isBuy: true, isPersonal: true, journalRefID: 1, locationID: station, quantity: 1, transactionID: 1, typeID: 645, unitPrice: 100),
						 ESI.Wallet.Transaction(clientID: characterID, date: Date(timeIntervalSinceNow: -3600 * 32), isBuy: true, isPersonal: true, journalRefID: 1, locationID: station, quantity: 1, transactionID: 1, typeID: 645, unitPrice: 100)]
			
			return ESI.Result(value: value, expires: nil, metadata: nil)
		}
	}
		
}
