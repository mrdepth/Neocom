//
//  DataManager.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import EVEAPI
import Alamofire

enum NCCachedResult<T> {
	case success(value: T, cacheRecord: NCCacheRecord?)
	case failure(Error)
	
	var cacheRecord: NCCacheRecord? {
		switch self {
		case let .success(_, record):
			return record
		default:
			return nil
		}
	}
	
	var error: Error? {
		switch self {
		case let .failure(error):
			return error
		default:
			return nil
		}
	}
}

extension NCCachedResult where T:Codable {
	var value: T? {
		switch self {
		case let .success(value, record):
			return record?.get() ?? value
		default:
			return nil
		}
	}
}

extension NCCachedResult where T == UIImage {
	var value: T? {
		switch self {
		case let .success(value, record):
			return record?.get() ?? value
		default:
			return nil
		}
	}
}

enum NCResult<T> {
	case success(T)
	case failure(Error)
}

extension Dictionary {
	init?(_ values: [(Key, Value)]?) {
		guard let values = values else {return nil}
		var dic = [Key: Value]()
		values.forEach {dic[$0] = $1}
		self = dic
	}
}

extension OAuth2Token {
	var identifier: String {
		return "\(self.characterID).\(self.refreshToken)"
	}
}


typealias NCLoaderCompletion<T> = (_ result: Result<T>, _ cacheTime: TimeInterval) -> Void

enum NCDataManagerError: Error, LocalizedError {
	case internalError
	case invalidResponse
	case noCacheData
	case noResult
	
	var errorDescription: String? {
		switch self {
		case .noResult:
			return NSLocalizedString("No Result", comment: "")
		default:
			return nil
		}
	}
}

class NCDataManager {

	var account: String?
	let token: OAuth2Token?
	let cachePolicy: URLRequest.CachePolicy
	var observer: NCManagedObjectObserver?
	
	private lazy var _esi: ESI = {
		if let token = self.token {
			return ESI(token: token, clientID: ESClientID, secretKey: ESSecretKey, server: .tranquility, cachePolicy: self.cachePolicy)
		}
		else {
			return ESI(cachePolicy: self.cachePolicy)
		}
	}()
	
	private var lock = NSLock()
	
	var esi: ESI {
		return lock.perform {self._esi}
	}

	private lazy var _zKillboard: ZKillboard = {
		return ZKillboard(cachePolicy: self.cachePolicy)
	}()
	
	var zKillboard: ZKillboard {
		return lock.perform {self._zKillboard}
	}

	let characterID: Int64
	private lazy var _corporationID: Future<Int64> = {
		return self.character().then { (result) -> Int64 in
			guard let corporationID = result.value?.corporationID else {throw NCDataManagerError.noCacheData}
			return Int64(corporationID)
		}
	}()
	
	var corporationID: Future<Int64> {
		return self._corporationID
	}
	
	init(account: NCAccount? = nil, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
		self.cachePolicy = cachePolicy
		if let acc = account {
			if acc.isInvalid {
				token = nil
			}
			else {
				token = acc.token
			}
			self.account = String(acc.characterID)
			characterID = acc.characterID
		}
		else {
			self.account = nil
			token = nil
			characterID = 0
		}
	}
	
	deinit {
		if let observer = observer {
			NotificationCenter.default.removeObserver(observer)
		}
	}

	/*func accountStatus(completionHandler: @escaping (NCCachedResult<EVE.Account.AccountStatus>) -> Void) {
		loadFromCache(forKey: "EVE.Account.AccountStatus", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.eve.account.accountStatus { result in
				completion(result, 3600.0)
			}
		})
	}*/

	func character(characterID: Int64? = nil) -> Future<CachedValue<ESI.Character.Information>> {
		let id = Int(characterID ?? self.characterID)
		return loadFromCache(forKey: "ESI.Character.Information.\(id)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.character.getCharactersPublicInformation(characterID: id))
	}

	
	func corporation(corporationID: Int64) -> Future<CachedValue<ESI.Corporation.Information>> {
		return loadFromCache(forKey: "ESI.Corporation.Information.\(corporationID)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.corporation.getCorporationInformation(corporationID: Int(corporationID)))
	}

	func alliance(allianceID: Int64) -> Future<CachedValue<ESI.Alliance.Information>> {
		return loadFromCache(forKey: "ESI.Alliance.Information.\(allianceID)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.alliance.getAllianceInformation(allianceID: Int(allianceID)))
	}

	func skillQueue() -> Future<CachedValue<[ESI.Skills.SkillQueueItem]>> {
		return loadFromCache(forKey: "ESI.Skills.SkillQueueItem", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.skills.getCharactersSkillQueue(characterID: Int(self.characterID)))
	}
	
	func skills() -> Future<CachedValue<ESI.Skills.CharacterSkills>> {
		return loadFromCache(forKey: "ESI.Skills.CharacterSkills", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.skills.getCharacterSkills(characterID: Int(self.characterID)))
	}
	
	
	func walletBalance() -> Future<CachedValue<Double>> {
		return loadFromCache(forKey: "ESI.WalletBalance", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.wallet.getCharactersWalletBalance(characterID: Int(self.characterID)))
	}

	func corpWalletBalance() -> Future<CachedValue<[ESI.Wallet.Balance]>> {
		return corporationID.then { corporationID in
			return self.loadFromCache(forKey: "ESI.CorpWalletBalance", account: self.account, cachePolicy: self.cachePolicy, elseLoad: self.esi.wallet.returnsCorporationsWalletBalance(corporationID: Int(corporationID)))
		}
	}

	func characterLocation() -> Future<CachedValue<ESI.Location.CharacterLocation>> {
		return loadFromCache(forKey: "ESI.Location.CharacterLocation", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.location.getCharacterLocation(characterID: Int(self.characterID)))
	}

	func characterShip() -> Future<CachedValue<ESI.Location.CharacterShip>> {
		return loadFromCache(forKey: "ESI.Location.CharacterShip", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.location.getCurrentShip(characterID: Int(self.characterID)))
	}
	
	func clones() -> Future<CachedValue<ESI.Clones.JumpClones>> {
		return loadFromCache(forKey: "ESI.Clones.JumpClones", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.clones.getClones(characterID: Int(self.characterID)))
	}

	func implants() -> Future<CachedValue<[Int]>> {
		return loadFromCache(forKey: "ESI.Clones.ActiveImplants", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.clones.getActiveImplants(characterID: Int(self.characterID)))
	}

	func attributes() -> Future<CachedValue<ESI.Skills.CharacterAttributes>> {
		return loadFromCache(forKey: "ESI.Skills.CharacterAttributes", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.skills.getCharacterAttributes(characterID: Int(self.characterID)))
	}

	
	func image(characterID: Int64, dimension: Int) -> Future<CachedValue<UIImage>> {
		return loadFromCache(forKey: "image.character.\(characterID).\(dimension)", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.image(characterID: Int(characterID), dimension: dimension * Int(UIScreen.main.scale))).then(on: .main) { result -> CachedValue<UIImage> in
			return .init(result.objectID)
		}
	}
	
	
	func image(corporationID: Int64, dimension: Int) -> Future<CachedValue<UIImage>> {
		return loadFromCache(forKey: "image.corporation.\(corporationID).\(dimension)", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.image(corporationID: Int(corporationID), dimension: dimension * Int(UIScreen.main.scale))).then(on: .main) { result -> CachedValue<UIImage> in
			return .init(result.objectID)
		}
	}
	
	func image(allianceID: Int64, dimension: Int) -> Future<CachedValue<UIImage>> {
		return loadFromCache(forKey: "image.alliance.\(allianceID).\(dimension)", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.image(allianceID: Int(allianceID), dimension: dimension * Int(UIScreen.main.scale))).then(on: .main) { result -> CachedValue<UIImage> in
			return .init(result.objectID)
		}
	}

	func image(typeID: Int, dimension: Int) -> Future<CachedValue<UIImage>> {
		return loadFromCache(forKey: "image.type.\(typeID).\(dimension)", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.image(typeID: typeID, dimension: dimension * Int(UIScreen.main.scale))).then(on: .main) { result -> CachedValue<UIImage> in
			return .init(result.objectID)
		}
	}
	
	private var cachedLocations: [Int64: NCLocation]?

	func locations(ids: Set<Int64>) -> Future<[Int64: NCLocation]> {
		let promise = Promise<[Int64: NCLocation]>()
		guard !ids.isEmpty else {
			try! promise.fulfill([:])
			return promise.future
		}
		
		var locations = [Int64: NCLocation]()
		var missing = Set<Int64>()
		var structures = Set<Int64>()
		
		var cachedLocations = self.cachedLocations ?? [:]
		
		let lifeTime = NCExtendedLifeTime(self)
		return NCDatabase.sharedDatabase!.performBackgroundTask { (managedObjectContext) in
			let staStations = NCDBStaStation.staStations(managedObjectContext: managedObjectContext)
			
			for id in ids {
				if let location = cachedLocations[id] {
					locations[id] = location
				}
				else if id > Int64(Int32.max) {
					structures.insert(id)
				}
				else if (66000000 < id && id < 66014933) { //staStations
					
					if let station = staStations[Int(id) - 6000001] {
						let location = NCLocation(station)
						locations[id] = location
						cachedLocations[id] = location
					}
					else {
						missing.insert(id)
					}
				}
				else if (60000000 < id && id < 61000000) { //staStations
					if let station = staStations[Int(id)] {
						let location = NCLocation(station)
						locations[id] = location
						cachedLocations[id] = location
					}
					else {
						missing.insert(id)
					}
				}
				else {
					missing.insert(id)
				}
			}
		}.then(on: .global(qos: .utility)) { _ -> [Int64: NCLocation] in
			if !missing.isEmpty {
				try? self.universeNames(ids: missing).get().value?.forEach { name in
					guard let location = NCLocation(name) else {return}
					locations[Int64(name.id)] = location
					cachedLocations[Int64(name.id)] = location
				}
			}
			structures.map {($0, self.universeStructure(structureID: $0))}
				.map { ($0, (try? $1.get())?.value) }
				.forEach { (id, value) in
					guard let value = value else {return}
					let location = NCLocation(value)
					locations[id] = location
					cachedLocations[id] = location
			}
			return locations
		}.finally {
			lifeTime.finalize()
		}
	}
	
	
	func universeNames(ids: Set<Int64>) -> Future<CachedValue<[ESI.Universe.Name]>> {
		let ids = ids.map{Int($0)}.sorted()
		return loadFromCache(forKey: "ESI.Universe.Name.\(ids.hashValue)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.universe.getNamesAndCategoriesForSetOfIDs(ids: ids))
	}

	func universeStructure(structureID: Int64) -> Future<CachedValue<ESI.Universe.StructureInformation>> {
		return loadFromCache(forKey: "ESI.Universe.StructureInformation.\(structureID)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.universe.getStructureInformation(structureID: structureID))
	}

	func updateMarketPrices() -> Future<Bool> {
		return NCCache.sharedCache!.performBackgroundTask { managedObjectContext -> Bool in
			let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: "ESI.Market.Price", account: nil)))?.last
			if record == nil || record!.isExpired {
				let result = try self.marketPrices().get()
				if let objects = try? managedObjectContext.fetch(NSFetchRequest<NCCachePrice>(entityName: "Price")) {
					for object in objects {
						managedObjectContext.delete(object)
					}
				}
				result.value?.forEach { price in
					let record = NCCachePrice(entity: NSEntityDescription.entity(forEntityName: "Price", in: managedObjectContext)!, insertInto: managedObjectContext)
					record.typeID = Int32(price.typeID)
					record.price = Double(price.averagePrice ?? 0)
				}
				if managedObjectContext.hasChanges {
					try? managedObjectContext.save()
				}
				return true
			}
			else {
				return false
			}
		}
	}
	
	func prices(typeIDs: Set<Int>) -> Future<[Int: Double]> {
		return NCCache.sharedCache!.performBackgroundTask { managedObjectContext -> [Int: Double] in
			let request = NSFetchRequest<NCCachePrice>(entityName: "Price")
			request.predicate = NSPredicate(format: "typeID in %@", typeIDs)
			var prices = [Int: Double]()
			for price in (try? managedObjectContext.fetch(request)) ?? [] {
				prices[Int(price.typeID)] = price.price
			}
			
			let missing = typeIDs.filter {return prices[$0] == nil}
			if missing.count > 0 {
				let isUpdated = try self.updateMarketPrices().get()
				if isUpdated {
					let request = NSFetchRequest<NCCachePrice>(entityName: "Price")
					request.predicate = NSPredicate(format: "typeID in %@", missing)
					for price in (try? managedObjectContext.fetch(request)) ?? [] {
						prices[Int(price.typeID)] = price.price
					}
					return prices
				}
				else {
					return prices
				}
			}
			else {
				return prices
			}
		}
	}

	func marketHistory(typeID: Int, regionID: Int) -> Future<CachedValue<[ESI.Market.History]>> {
		return loadFromCache(forKey: "ESI.Market.History.\(regionID).\(typeID)", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.market.listHistoricalMarketStatisticsInRegion(regionID: regionID, typeID: typeID))
	}

	func marketOrders(typeID: Int, regionID: Int) -> Future<CachedValue<[ESI.Market.Order]>> {
		return loadFromCache(forKey: "ESI.Market.Order.\(regionID).\(typeID)", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.market.listOrdersInRegion(orderType: .all, regionID: regionID, typeID: typeID))
	}
	
	func search(_ string: String, categories: [ESI.Search.SearchCategories], strict: Bool = false) -> Future<CachedValue<ESI.Search.SearchResult>> {
		return loadFromCache(forKey: "ESI.Search.SearchResult.\(categories.hashValue).\(string.lowercased().hashValue).\(strict)", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.search.search(categories: categories, search: string, strict: strict))
	}

	func searchNames(_ string: String, categories: [ESI.Search.SearchCategories], strict: Bool = false) -> Future<[Int64: NSManagedObjectID]> {
		return self.search(string, categories: categories).then(on: .global(qos: .utility)) { result -> [Int64: NSManagedObjectID] in
			if let searchResult = result.value {
				var ids = Set<Int>()
				ids.formUnion(searchResult.agent ?? [])
				ids.formUnion(searchResult.alliance ?? [])
				ids.formUnion(searchResult.character ?? [])
				ids.formUnion(searchResult.constellation ?? [])
				ids.formUnion(searchResult.corporation ?? [])
				ids.formUnion(searchResult.faction ?? [])
				ids.formUnion(searchResult.inventoryType ?? [])
				ids.formUnion(searchResult.region ?? [])
				ids.formUnion(searchResult.solarSystem ?? [])
				ids.formUnion(searchResult.station ?? [])
				
				if ids.count > 0 {
					return try self.contacts(ids: Set(ids.map{Int64($0)})).get()
				}
				else {
					return [:]
				}
			}
			else {
				return [:]
			}
		}

/*		loadFromCache(forKey: "ESI.Search.SearchNamesResult.\(categories.hashValue).\(string.lowercased().hashValue).\(strict)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			
			self.search(string, categories: categories) { result in
				switch result {
				case let .success(value):
					let searchResult = value.value
					var ids = [Int]()
					ids.append(contentsOf: searchResult.agent ?? [])
					ids.append(contentsOf: searchResult.alliance ?? [])
					ids.append(contentsOf: searchResult.character ?? [])
					ids.append(contentsOf: searchResult.constellation ?? [])
					ids.append(contentsOf: searchResult.corporation ?? [])
					ids.append(contentsOf: searchResult.faction ?? [])
					ids.append(contentsOf: searchResult.inventorytype ?? [])
					ids.append(contentsOf: searchResult.region ?? [])
					ids.append(contentsOf: searchResult.solarsystem ?? [])
					ids.append(contentsOf: searchResult.station ?? [])
					ids.append(contentsOf: searchResult.wormhole ?? [])
					
					if ids.count > 0 {
						self.universeNames(ids: Set(ids.map{ Int64($0) }) ) { result in
							switch result {
							case let .success(value):
								var names = [Int: String]()
								value.value.forEach {names[$0.id] = $0.name}
								
								func map(_ key: Int) -> (Int64, String)? {
									guard let value = names[key] else {return nil}
									return (Int64(key), value)
								}
								var result: [String: [Int64: String]] = [:]
								result[ESI.Search.SearchCategories.agent.rawValue] = Dictionary(searchResult.agent?.compactMap(map))
								result[ESI.Search.SearchCategories.alliance.rawValue] = Dictionary(searchResult.alliance?.compactMap(map))
								result[ESI.Search.SearchCategories.character.rawValue] = Dictionary(searchResult.character?.compactMap(map))
								result[ESI.Search.SearchCategories.constellation.rawValue] = Dictionary(searchResult.constellation?.compactMap(map))
								result[ESI.Search.SearchCategories.corporation.rawValue] = Dictionary(searchResult.corporation?.compactMap(map))
								result[ESI.Search.SearchCategories.faction.rawValue] = Dictionary(searchResult.faction?.compactMap(map))
								result[ESI.Search.SearchCategories.inventorytype.rawValue] = Dictionary(searchResult.inventorytype?.compactMap(map))
								result[ESI.Search.SearchCategories.region.rawValue] = Dictionary(searchResult.region?.compactMap(map))
								result[ESI.Search.SearchCategories.solarsystem.rawValue] = Dictionary(searchResult.solarsystem?.compactMap(map))
								result[ESI.Search.SearchCategories.station.rawValue] = Dictionary(searchResult.station?.compactMap(map))
								result[ESI.Search.SearchCategories.wormhole.rawValue] = Dictionary(searchResult.wormhole?.compactMap(map))
								completion(.success(result), 3600.0 * 12)
								
							case let .failure(error):
								completion(.failure(error), 3600.0 * 12)
							}
						}
					}
					else {
						completion(.success([:]), 3600.0 * 12)
					}
				case let .failure(error):
					completion(.failure(error), 3600.0 * 12)
				}
			}
			
//			self.esi.search.search(categories: categories, search: string, strict: strict) { result in
//				completion(result, 3600.0 * 12)
//			}
		})*/
	}

	func sendMail(body: String, subject: String, recipients: [ESI.Mail.Recipient]) -> Future<Int> {
		let mail = ESI.Mail.NewMail(approvedCost: nil, body: body, recipients: recipients, subject: subject)
		return self.esi.mail.sendNewMail(characterID: Int(characterID), mail: mail).then { result in
			return result.value
		}
	}
	
	func returnMailHeaders(lastMailID: Int64? = nil, labels: [Int64]) -> Future<CachedValue<[ESI.Mail.Header]>> {
		let labels = labels.sorted()
		return loadFromCache(forKey: "ESI.Mail.Header.\(labels.hashValue).\(lastMailID ?? 0)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.mail.returnMailHeaders(characterID: Int(self.characterID), labels: labels.map{Int($0)}, lastMailID: lastMailID != nil ? Int(lastMailID!) : nil))
	}

	func returnMailBody(mailID: Int64) -> Future<CachedValue<ESI.Mail.MailBody>> {
		return loadFromCache(forKey: "ESI.Mail.MailBody.\(mailID)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.mail.returnMail(characterID: Int(self.characterID), mailID: Int(mailID)))
	}

	func returnMailingLists() -> Future<CachedValue<[ESI.Mail.Subscription]>> {
		return loadFromCache(forKey: "ESI.Mail.Subscription", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.mail.returnMailingListSubscriptions(characterID: Int(self.characterID)))
	}

	
	func mailLabels() -> Future<CachedValue<ESI.Mail.MailLabelsAndUnreadCounts>> {
		return loadFromCache(forKey: "ESI.Mail.MailLabelsAndUnreadCounts", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.mail.getMailLabelsAndUnreadCounts(characterID: Int(self.characterID)))
	}
	
	func calendarEvents() -> Future<CachedValue<[ESI.Calendar.Summary]>> {
		return loadFromCache(forKey: "ESI.Calendar.Summary", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.calendar.listCalendarEventSummaries(characterID: Int(self.characterID)))
	}

	func calendarEventDetails(eventID: Int64) -> Future<CachedValue<ESI.Calendar.Event>> {
		return loadFromCache(forKey: "ESI.Calendar.Event.\(eventID)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.calendar.getAnEvent(characterID: Int(self.characterID), eventID: Int(eventID)))
	}

	
	func markRead(mail: ESI.Mail.Header) -> Future<String> {
		guard let mailID = mail.mailID else {
			let promise = Promise<String>()
			try! promise.fail(NCDataManagerError.internalError)
			return promise.future
		}
		
		let contents = ESI.Mail.UpdateContents(labels: mail.labels, read: true)
		return self.esi.mail.updateMetadataAboutMail(characterID: Int(self.characterID), contents: contents, mailID: Int(mailID)).then { result in
			return result.value
		}
	}
	
	func delete(mailID: Int64) -> Future<String> {
		return self.esi.mail.deleteMail(characterID: Int(self.characterID), mailID: Int(mailID)).then { result in
			return result.value
		}
	}

	
	private static var invalidIDs = Set<Int64>()
	
	func contacts(ids: Set<Int64>) -> Future<[Int64: NSManagedObjectID]> {
		let ids = ids.subtracting(NCDataManager.invalidIDs)
		
		return NCCache.sharedCache!.performBackgroundTask { managedObjectContext -> [Int64: NSManagedObjectID] in
			managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

			let request = NSFetchRequest<NCContact>(entityName: "Contact")
			request.predicate = NSPredicate(format: "contactID in %@", ids)
			
			var contacts = try managedObjectContext.fetch(request)

			var missing = ids.subtracting(contacts.map{$0.contactID})
			
			if !missing.isEmpty {
				let mailingLists: [ESI.Mail.Subscription]?
				let names: [ESI.Universe.Name]?
				let dispatchGroup = DispatchGroup()

				do {
					let universeNames = try self.universeNames(ids: missing).get().value
					names = universeNames
					missing.subtract(Set(universeNames?.map {Int64($0.id)} ?? []))
				}
				catch {
					names = []
					if (error as? AFError)?.responseCode == 404 {
						DispatchQueue.main.async {
							NCDataManager.invalidIDs.formUnion(missing)
						}
					}
				}
				
				if !missing.isEmpty {
					dispatchGroup.enter()
					mailingLists = (try? self.returnMailingLists().get())?.value
				}
				else {
					mailingLists = nil
				}
				
				
				var result = names?.map{($0.id, $0.name, $0.category.rawValue)} ?? []
				result.append(contentsOf: mailingLists?.map {($0.mailingListID, $0.name, ESI.Mail.RecipientType.mailingList.rawValue)} ?? [])
				
				for name in result {
					let contact = NCContact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: managedObjectContext)!, insertInto: managedObjectContext)
					contact.contactID = Int64(name.0)
					contact.name = name.1
					contact.type = name.2
					
					contacts.append(contact)
				}
				if managedObjectContext.hasChanges {
					try! managedObjectContext.save()
				}
			}
			return Dictionary(contacts.map{($0.contactID, $0.objectID)}, uniquingKeysWith: { (first, _) in first})
		}
	}
	
	func marketPrices() -> Future<CachedValue<[ESI.Market.Price]>> {
		return loadFromCache(forKey: "ESI.Market.Price", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.market.listMarketPrices())
	}

	func assets(page: Int? = nil) -> Future<CachedValue<[ESI.Assets.Asset]>> {
		return loadFromCache(forKey: "ESI.Assets.Asset.\(page ?? 0)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.assets.getCharacterAssets(characterID: Int(self.characterID), page: page))
	}

	func corpAssets(page: Int? = nil) -> Future<CachedValue<[ESI.Assets.CorpAsset]>> {
		return corporationID.then { corporationID in
			return self.loadFromCache(forKey: "ESI.Assets.ESI.Assets.CorpAsset.\(page ?? 0)", account: self.account, cachePolicy: self.cachePolicy, elseLoad: self.esi.assets.getCorporationAssets(corporationID: Int(corporationID), page: page))
		}
	}

	func divisions() -> Future<CachedValue<ESI.Corporation.Divisions>> {
		return corporationID.then { corporationID in
			return self.loadFromCache(forKey: "ESI.Corporation.Division", account: self.account, cachePolicy: self.cachePolicy, elseLoad: self.esi.corporation.getCorporationDivisions(corporationID: Int(corporationID)))
		}
	}

	func blueprints() -> Future<CachedValue<[ESI.Character.Blueprint]>> {
		return loadFromCache(forKey: "ESI.Character.Blueprint", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.character.getBlueprints(characterID: Int(self.characterID)))
	}
	
	func corpIndustryJobs() -> Future<CachedValue<[ESI.Industry.CorpJob]>> {
		return corporationID.then { corporationID in
			return self.loadFromCache(forKey: "ESI.Industry.Job", account: self.account, cachePolicy: self.cachePolicy, elseLoad: self.esi.industry.listCorporationIndustryJobs(corporationID: Int(corporationID), includeCompleted: true))
		}
	}

	
	func industryJobs() -> Future<CachedValue<[ESI.Industry.Job]>> {
		return loadFromCache(forKey: "ESI.Industry.Job", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.industry.listCharacterIndustryJobs(characterID: Int(self.characterID), includeCompleted: true))
	}

	func corpMarketOrders() -> Future<CachedValue<[ESI.Market.CorpOrder]>> {
		return corporationID.then { corporationID in
			return self.loadFromCache(forKey: "ESI.Market.CorpOrder", account: self.account, cachePolicy: self.cachePolicy, elseLoad: self.esi.market.listOpenOrdersFromCorporation(corporationID: Int(corporationID)))
		}
	}

	func marketOrders() -> Future<CachedValue<[ESI.Market.CharacterOrder]>> {
		return loadFromCache(forKey: "ESI.Market.CharacterOrder", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.market.listOpenOrdersFromCharacter(characterID: Int(self.characterID)))
	}

	func walletJournal() -> Future<CachedValue<[ESI.Wallet.WalletJournalItem]>> {
		return loadFromCache(forKey: "ESI.Wallet.WalletJournalItem", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.wallet.getCharacterWalletJournal(characterID: Int(self.characterID)))
	}

	func corpWalletJournal(division: Int) -> Future<CachedValue<[ESI.Wallet.CorpWalletsJournalItem]>> {
		return corporationID.then { corporationID in
			return self.loadFromCache(forKey: "ESI.Wallet.CorpWalletsJournalItem.\(division)", account: self.account, cachePolicy: self.cachePolicy, elseLoad: self.esi.wallet.getCorporationWalletJournal(corporationID: Int(corporationID), division: division))
		}
	}

	func walletTransactions() -> Future<CachedValue<[ESI.Wallet.Transaction]>> {
		return loadFromCache(forKey: "ESI.Wallet.Transaction", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.wallet.getWalletTransactions(characterID: Int(self.characterID)))
	}

	func corpWalletTransactions(division: Int) -> Future<CachedValue<[ESI.Wallet.CorpTransaction]>> {
		return corporationID.then { corporationID in
			return self.loadFromCache(forKey: "ESI.Wallet.CorpTransaction.\(division)", account: self.account, cachePolicy: self.cachePolicy, elseLoad: self.esi.wallet.getCorporationWalletTransactions(corporationID: Int(corporationID), division: division))
		}
	}


//	func refTypes(completionHandler: @escaping (NCCachedResult<EVE.Eve.RefTypes>) -> Void) {
//		loadFromCache(forKey: "EVE.Eve.RefTypes", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
//			self.eve.eve.refTypes { result in
//				completion(result, 3600.0 * 24 * 7)
//			}
//		})
//	}

	func contracts() -> Future<CachedValue<[ESI.Contracts.Contract]>> {
		return loadFromCache(forKey: "ESI.Contracts.Contract", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.contracts.getContracts(characterID: Int(self.characterID)))
	}

	func contractItems(contractID: Int64) -> Future<CachedValue<[ESI.Contracts.Item]>> {
		return loadFromCache(forKey: "ESI.Contracts.Item.\(contractID)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.contracts.getContractItems(characterID: Int(self.characterID), contractID: Int(contractID)))
	}

	func contractBids(contractID: Int64) -> Future<CachedValue<[ESI.Contracts.Bid]>> {
		return loadFromCache(forKey: "ESI.Contracts.Bid.\(contractID)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.contracts.getContractBids(characterID: Int(self.characterID), contractID: Int(contractID)))
	}


	func incursions() -> Future<CachedValue<[ESI.Incursions.Incursion]>> {
		return loadFromCache(forKey: "ESI.Incursions.Incursion", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.incursions.listIncursions())
	}
	
	func colonies() -> Future<CachedValue<[ESI.PlanetaryInteraction.Colony]>> {
		return loadFromCache(forKey: "ESI.PlanetaryInteraction.Colony", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.planetaryInteraction.getColonies(characterID: Int(self.characterID)))
	}
	
	func colonyLayout(planetID: Int) -> Future<CachedValue<ESI.PlanetaryInteraction.ColonyLayout>> {
		return loadFromCache(forKey: "ESI.PlanetaryInteraction.ColonyLayout.\(planetID)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.planetaryInteraction.getColonyLayout(characterID: Int(self.characterID), planetID: planetID))
	}

	func killmails(page: Int? = nil) -> Future<CachedValue<[ESI.Killmails.Recent]>> {
		return loadFromCache(forKey: "ESI.Killmails.Recent.\(page ?? 0)", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.killmails.getCharactersRecentKillsAndLosses(characterID: Int(self.characterID), page: page))
	}
	
	func killmailInfo(killmailHash: String, killmailID: Int64) -> Future<CachedValue<ESI.Killmails.Killmail>> {
		return loadFromCache(forKey: "ESI.KillMails.Killmail.\(killmailID).\(killmailHash)", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.killmails.getSingleKillmail(killmailHash: killmailHash, killmailID: Int(killmailID)))
	}
	
	func zKillmails(filter: [ZKillboard.Filter], page: Int) -> Future<CachedValue<[ZKillboard.Killmail]>> {
		let key = filter.map{$0.value}.sorted().joined(separator: "/")
		return loadFromCache(forKey: "ZKillboard.Killmail.\(key)/\(page)", account: nil, cachePolicy: cachePolicy, elseLoad: self.zKillboard.kills(filter: filter, page: page))
	}
	
	func rss(url: URL) -> Future<CachedValue<RSS.Feed>> {
		return loadFromCache(forKey: "RSS.Feed.\(url.absoluteString)", account: nil, cachePolicy: cachePolicy, elseLoad: { () -> Future<ESI.Result<RSS.Feed>> in
			let promise = Promise<ESI.Result<RSS.Feed>>()
			Alamofire.request(url, method: .get).validate().responseRSS { (response: DataResponse<RSS.Feed>) in
				do {
					switch response.result {
					case let .success(value):
						try promise.fulfill(.init(value: value, cached: 60))
					case let .failure(error):
						throw error
					}
				}
				catch {
					try! promise.fail(error)
				}
			}
			return promise.future
		}())
	}

	
	func fittings() -> Future<CachedValue<[ESI.Fittings.Fitting]>> {
		return loadFromCache(forKey: "ESI.Fittings.Fitting", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.fittings.getFittings(characterID: Int(self.characterID)))
	}
	
	func deleteFitting(fittingID: Int) -> Future<String> {
		return self.esi.fittings.deleteFitting(characterID: Int(self.characterID), fittingID: fittingID).then { result in
			return result.value
		}
	}
	
	func createFitting(fitting: ESI.Fittings.MutableFitting, completionHandler: @escaping (Result<ESI.Fittings.CreateFittingResult>) -> Void) {
		self.esi.fittings.createFitting(characterID: Int(self.characterID), fitting: fitting).then { result in
			completionHandler(.success(result.value))
		}.catch { error in
			completionHandler(.failure(error))
		}
	}
	
	func serverStatus() -> Future<CachedValue<ESI.Status.ServerStatus>> {
		return loadFromCache(forKey: "ESI.Status.ServerStatus", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.status.retrieveTheUptimeAndPlayerCounts())
	}
	
	func loyaltyPoints() -> Future<CachedValue<[ESI.Loyalty.Point]>> {
		return loadFromCache(forKey: "ESI.Loyalty.Point", account: account, cachePolicy: cachePolicy, elseLoad: self.esi.loyalty.getLoyaltyPoints(characterID: Int(self.characterID)))
	}
	
	func loyaltyStoreOffers(corporationID: Int64) -> Future<CachedValue<[ESI.Loyalty.Offer]>> {
		return loadFromCache(forKey: "ESI.Loyalty.Offer.\(corporationID)", account: nil, cachePolicy: cachePolicy, elseLoad: self.esi.loyalty.listLoyaltyStoreOffers(corporationID: Int(corporationID)))
	}

	//MARK: Private
	
	private var completionHandlers: [String: [(Any?, NCCacheRecord?, Error?) -> Void]] = [:]
//	private var active: Atomic<[String: Future<NSManagedObjectID>]> = Atomic([:])
	
	private func loadFromCache<T: Codable> (forKey key: String,
								   account: String?,
								   cachePolicy:URLRequest.CachePolicy,
								   elseLoad loader: @escaping @autoclosure () -> Future<ESI.Result<T>>) -> Future<CachedValue<T>> {
//		let id = key + (account ?? "")
		
		let promise = Promise<CachedValue<T>>()
		guard let cache = NCCache.sharedCache else {
			try! promise.fail(NCDataManagerError.internalError)
			return promise.future
		}
		
		let future: Future<NSManagedObjectID>
		let progress = Progress(totalUnitCount: 1)
		
		switch cachePolicy {
		case .reloadIgnoringLocalCacheData:
			progress.becomeCurrent(withPendingUnitCount: 1)
			future = loader().then { result in
				return cache.store(result.value, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: result.cached), error: nil)
			}
			progress.resignCurrent()
			
		case .returnCacheDataElseLoad:
			future = cache.performBackgroundTask { (managedObjectContext) -> NSManagedObjectID in
				let record = try managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)).last
				let object: T? = record?.get() ?? nil
				if let record = record, object != nil {
					progress.completedUnitCount += 1
					return record.objectID
				}
				else {
					let result = try loader().get()
					progress.completedUnitCount += 1
					return try cache.store(result.value, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: result.cached), error: nil, into: managedObjectContext)
				}
			}

		case .returnCacheDataDontLoad:
			future = cache.performBackgroundTask { (managedObjectContext) -> NSManagedObjectID in
				let record = try managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)).last
				let object: T? = record?.get() ?? nil
				if let record = record, object != nil {
					return record.objectID
				}
				else {
					throw NCDataManagerError.noCacheData
				}
			}

		default:
			future = cache.performBackgroundTask { (managedObjectContext) -> NSManagedObjectID in
				let record = try managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)).last
				let object: T? = record?.get() ?? nil
				let expired = record?.isExpired ?? true
				
				if let record = record, object != nil {
					if expired {
						loader().then { result in
							cache.store(result.value, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: result.cached), error: nil)
						}
					}
					return record.objectID
				}
				else {
					let result = try loader().get()
					return try cache.store(result.value, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: result.cached), error: nil, into: managedObjectContext)
				}
			}
		}
		
		let lifeTime = NCExtendedLifeTime(self)
		future.then { result in
			try promise.fulfill(.init(result))
			}
			.finally {
				lifeTime.finalize()
			}
			.catch { error in
				try! promise.fail(error)
		}

		
		return promise.future
	}
}
