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
	
	var value: T? {
		switch self {
		case let .success(value, record):
			return record?.data?.data as? T ?? value
		default:
			return nil
		}
	}
	
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


fileprivate var tokens: NSMapTable<NSString, OAuth2Token> = NSMapTable.strongToWeakObjects()
fileprivate var retriers: NSMapTable<NSString, OAuth2Retrier> = NSMapTable.strongToWeakObjects()


class NCDataManager {
	enum NCDataManagerError: Error {
		case internalError
		case invalidResponse
		case noCacheData
	}
	var account: String?
	let token: OAuth2Token?
	let cachePolicy: URLRequest.CachePolicy
	var observer: NCManagedObjectObserver?
	
	lazy var retrier: OAuth2Retrier? = {
		guard let token = self.token else {return nil}
		
		let key = token.identifier as NSString
		if let cached = retriers.object(forKey: key) {
			return cached
		}
		else {
			let retrier = OAuth2Retrier(token: token, clientID: ESClientID, secretKey: ESSecretKey)
			retriers.setObject(retrier, forKey: key)
			return retrier
		}
	}()
	
	lazy var esi: ESI = {
		if let token = self.token {
			return ESI(token: token, clientID: ESClientID, secretKey: ESSecretKey, server: .tranquility, cachePolicy: self.cachePolicy, retrier: self.retrier)
		}
		else {
			return ESI(cachePolicy: self.cachePolicy)
		}
	}()

//	lazy var eve: EVE = {
//		if let token = self.token {
//			return EVE(token: token, clientID: ESClientID, secretKey: ESSecretKey, server: .tranquility, cachePolicy: self.cachePolicy, retrier: self.retrier)
//		}
//		else {
//			return EVE(cachePolicy: self.cachePolicy)
//		}
//	}()
	
	lazy var zKillboard: ZKillboard = {
		return ZKillboard(cachePolicy: self.cachePolicy)
	}()

	var characterID: Int64 {
		return token?.characterID ?? 0
	}
	
	init(account: NCAccount? = nil, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
		self.cachePolicy = cachePolicy
		if let acc = account {
			/*observer = NCManagedObjectObserver(managedObjectID: acc.objectID) {[weak self] (_, _) in
				self?.token = acc.token
			}*/
			self.account = String(acc.characterID)
			let token = acc.token
			let key = token.identifier as NSString
			if let cached = tokens.object(forKey: key) {
				self.token = cached
			}
			else {
				tokens.setObject(token, forKey: key)
				self.token = token
			}
		}
		else {
			self.account = nil
			self.token = nil
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

	
	func character(characterID: Int64? = nil, completionHandler: @escaping (NCCachedResult<ESI.Character.Information>) -> Void) {
		let id = Int(characterID ?? self.characterID)
		loadFromCache(forKey: "ESI.Character.Information.\(id)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.character.getCharactersPublicInformation(characterID: id) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func corporation(corporationID: Int64, completionHandler: @escaping (NCCachedResult<ESI.Corporation.Information>) -> Void) {
		loadFromCache(forKey: "ESI.Corporation.Information.\(corporationID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.corporation.getCorporationInformation(corporationID: Int(corporationID)) { result in
				completion(result, 3600.0)
			}
		})
	}

	func alliance(allianceID: Int64, completionHandler: @escaping (NCCachedResult<ESI.Alliance.Information>) -> Void) {
		loadFromCache(forKey: "ESI.Alliance.Information.\(allianceID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.alliance.getAllianceInformation(allianceID: Int(allianceID)) { result in
				completion(result, 3600.0)
			}
		})
	}

	func skillQueue(completionHandler: @escaping (NCCachedResult<[ESI.Skills.SkillQueueItem]>) -> Void) {
		loadFromCache(forKey: "ESI.Skills.SkillQueueItem", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.skills.getCharactersSkillQueue(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func skills(completionHandler: @escaping (NCCachedResult<ESI.Skills.CharacterSkills>) -> Void) {
		loadFromCache(forKey: "ESI.Skills.CharacterSkills", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.skills.getCharacterSkills(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	
	func walletBalance(completionHandler: @escaping (NCCachedResult<Double>) -> Void) {
		loadFromCache(forKey: "ESI.WalletBalance", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.wallet.getCharactersWalletBalance(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func characterLocation(completionHandler: @escaping (NCCachedResult<ESI.Location.CharacterLocation>) -> Void) {
		loadFromCache(forKey: "ESI.Location.CharacterLocation", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.location.getCharacterLocation(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}

	func characterShip(completionHandler: @escaping (NCCachedResult<ESI.Location.CharacterShip>) -> Void) {
		loadFromCache(forKey: "ESI.Location.CharacterShip", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.location.getCurrentShip(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}
	
//	func clones(completionHandler: @escaping (NCCachedResult<ESI.Clones.JumpClones>) -> Void) {
//		loadFromCache(forKey: "ESI.Clones.JumpClones", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
//			self.esi.clones.getClones(characterID: Int(self.characterID)) { result in
//				completion(result, 3600.0)
//			}
//		})
//	}
	
	func clones(completionHandler: @escaping (NCCachedResult<ESI.Clones.JumpClones>) -> Void) {
		loadFromCache(forKey: "ESI.Clones.JumpClones", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.clones.getClones(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}

	func implants(completionHandler: @escaping (NCCachedResult<[Int]>) -> Void) {
		loadFromCache(forKey: "ESI.Clones.ActiveImplants", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.clones.getActiveImplants(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}

	func attributes(completionHandler: @escaping (NCCachedResult<ESI.Skills.CharacterAttributes>) -> Void) {
		loadFromCache(forKey: "ESI.Skills.CharacterAttributes", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.skills.getCharacterAttributes(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}

	
	func image(characterID: Int64, dimension: Int, completionHandler: @escaping (NCCachedResult<UIImage>) -> Void) {
		loadFromCache(forKey: "image.character.\(characterID).\(dimension)", account: nil, cachePolicy: cachePolicy, completionHandler: { (result: NCCachedResult<Data>) in
			switch result {
			case let .success(value, cacheRecord):
				if let image = UIImage(data: value, scale: UIScreen.main.scale) {
					completionHandler(.success(value: image, cacheRecord: cacheRecord))
				}
				else {
					completionHandler(.failure(NCDataManagerError.invalidResponse))
				}
			case let .failure(error):
				completionHandler(.failure(error))
			}
		}, elseLoad: { completion in
			self.esi.image(characterID: Int(characterID), dimension: dimension * Int(UIScreen.main.scale)) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}
	
	func image(corporationID: Int64, dimension: Int, completionHandler: @escaping (NCCachedResult<UIImage>) -> Void) {
		loadFromCache(forKey: "image.corporation.\(corporationID).\(dimension)", account: nil, cachePolicy: cachePolicy, completionHandler: { (result: NCCachedResult<Data>) in
			switch result {
			case let .success(value, cacheRecord):
				if let image = UIImage(data: value, scale: UIScreen.main.scale) {
					completionHandler(.success(value: image, cacheRecord: cacheRecord))
				}
				else {
					completionHandler(.failure(NCDataManagerError.invalidResponse))
				}
			case let .failure(error):
				completionHandler(.failure(error))
			}
		}, elseLoad: { completion in
			self.esi.image(corporationID: Int(corporationID), dimension: dimension * Int(UIScreen.main.scale)) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}
	
	func image(allianceID: Int64, dimension: Int, completionHandler: @escaping (NCCachedResult<UIImage>) -> Void) {
		loadFromCache(forKey: "image.alliance.\(allianceID).\(dimension)", account: nil, cachePolicy: cachePolicy, completionHandler: { (result: NCCachedResult<Data>) in
			switch result {
			case let .success(value, cacheRecord):
				if let image = UIImage(data: value, scale: UIScreen.main.scale) {
					completionHandler(.success(value: image, cacheRecord: cacheRecord))
				}
				else {
					completionHandler(.failure(NCDataManagerError.invalidResponse))
				}
			case let .failure(error):
				completionHandler(.failure(error))
			}
		}, elseLoad: { completion in
			self.esi.image(allianceID: Int(allianceID), dimension: dimension * Int(UIScreen.main.scale)) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	func image(typeID: Int, dimension: Int, completionHandler: @escaping (NCCachedResult<UIImage>) -> Void) {
		loadFromCache(forKey: "image.type.\(typeID).\(dimension)", account: nil, cachePolicy: cachePolicy, completionHandler: { (result: NCCachedResult<Data>) in
			switch result {
			case let .success(value, cacheRecord):
				if let image = UIImage(data: value, scale: UIScreen.main.scale) {
					completionHandler(.success(value: image, cacheRecord: cacheRecord))
				}
				else {
					completionHandler(.failure(NCDataManagerError.invalidResponse))
				}
			case let .failure(error):
				completionHandler(.failure(error))
			}
		}, elseLoad: { completion in
			self.esi.image(typeID: typeID, dimension: dimension * Int(UIScreen.main.scale)) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}
	
	private var cachedLocations: [Int64: NCLocation]?

	func locations(ids: Set<Int64>, completionHandler: @escaping ([Int64: NCLocation]) -> Void) {
		guard !ids.isEmpty else {
			completionHandler([:])
			return
		}
		
		var locations = [Int64: NCLocation]()
		var missing = Set<Int64>()
		var structures = Set<Int64>()
		
		var cachedLocations = self.cachedLocations ?? [:]
		
		for id in ids {
			if let location = cachedLocations[id] {
				locations[id] = location
			}
			else if id > Int64(Int32.max) {
				structures.insert(id)
			}
			else if (66000000 < id && id < 66014933) { //staStations
				if let station = NCDatabase.sharedDatabase?.staStations[Int(id) - 6000001] {
					let location = NCLocation(station)
					locations[id] = location
					cachedLocations[id] = location
				}
				else {
					missing.insert(id)
				}
			}
			else if (60000000 < id && id < 61000000) { //staStations
				if let station = NCDatabase.sharedDatabase?.staStations[Int(id)] {
					let location = NCLocation(station)
					locations[id] = location
					cachedLocations[id] = location
				}
				else {
					missing.insert(id)
				}
			}
			else if let int = Int(exactly: id) { //mapDenormalize
				
				if let mapDenormalize = NCDatabase.sharedDatabase?.mapDenormalize[int] {
					let location = NCLocation(mapDenormalize)
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
		let dispatchGroup = DispatchGroup()
		let lifeTime = NCExtendedLifeTime(self)
		if missing.count > 0 {
			dispatchGroup.enter()
			self.universeNames(ids: missing) { result in
				let _ = self
				switch result {
				case let .success(value, _):
					for name in value {
						if let location = NCLocation(name) {
							locations[Int64(name.id)] = location
							cachedLocations[Int64(name.id)] = location
						}
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
			}
		}
		for id in structures {
			dispatchGroup.enter()
			self.universeStructure(structureID: id) { result in
				let _ = self
				switch result {
				case let .success(value, _):
					let location = NCLocation(value)
					locations[id] = location
					cachedLocations[id] = location
				case .failure:
					break
				}
				dispatchGroup.leave()
			}
		}
		
		dispatchGroup.notify(queue: .main) {
			self.cachedLocations = cachedLocations
			completionHandler(locations)
			lifeTime.finalize()
		}
	}
	
	func universeNames(ids: Set<Int64>, completionHandler: @escaping (NCCachedResult<[ESI.Universe.Name]>) -> Void) {
		let ids = ids.map{Int($0)}.sorted()
		loadFromCache(forKey: "ESI.Universe.Name.\(ids.hashValue)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.universe.getNamesAndCategoriesForSetOfIDs(ids: ids) { result in
				completion(result, 3600.0 * 24)
			}
		})
	}

	func universeStructure(structureID: Int64, completionHandler: @escaping (NCCachedResult<ESI.Universe.StructureInformation>) -> Void) {
		loadFromCache(forKey: "ESI.Universe.StructureInformation.\(structureID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.universe.getStructureInformation(structureID: structureID) { result in
				completion(result, 3600.0 * 24)
			}
		})
	}

	
	func updateMarketPrices(completionHandler: ((_ isUpdated: Bool) -> Void)? = nil) {
		let lifeTime = NCExtendedLifeTime(self)
		NCCache.sharedCache?.performBackgroundTask{ managedObjectContext in
			let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: "ESI.Market.Price", account: nil)))?.last
			if record == nil || record!.isExpired {
				self.marketPrices { result in
					let _ = self
					switch result {
					case let .success(value, _):
						NCCache.sharedCache?.performBackgroundTask{ managedObjectContext in
							if let objects = try? managedObjectContext.fetch(NSFetchRequest<NCCachePrice>(entityName: "Price")) {
								for object in objects {
									managedObjectContext.delete(object)
								}
							}
							for price in value {
								let record = NCCachePrice(entity: NSEntityDescription.entity(forEntityName: "Price", in: managedObjectContext)!, insertInto: managedObjectContext)
								record.typeID = Int32(price.typeID)
								record.price = Double(price.averagePrice ?? 0)
							}
							if managedObjectContext.hasChanges {
								try? managedObjectContext.save()
							}
							DispatchQueue.main.async {
								completionHandler?(true)
								lifeTime.finalize()
							}
						}
					default:
						completionHandler?(false)
						lifeTime.finalize()
					}
				}
			}
			else {
				DispatchQueue.main.async {
					completionHandler?(false)
					lifeTime.finalize()
				}
			}
		}
	}
	
	func prices(typeIDs: Set<Int>, completionHandler: @escaping ([Int: Double]) -> Void) {
		let lifeTime = NCExtendedLifeTime(self)
		NCCache.sharedCache?.performBackgroundTask { managedObjectContext in
			let request = NSFetchRequest<NCCachePrice>(entityName: "Price")
			request.predicate = NSPredicate(format: "typeID in %@", typeIDs)
			var prices = [Int: Double]()
			for price in (try? managedObjectContext.fetch(request)) ?? [] {
				prices[Int(price.typeID)] = price.price
			}
			
			let missing = typeIDs.filter {return prices[$0] == nil}
			if missing.count > 0 {
				self.updateMarketPrices { isUpdated in
					if isUpdated {
						NCCache.sharedCache?.performBackgroundTask { managedObjectContext in
							let request = NSFetchRequest<NCCachePrice>(entityName: "Price")
							request.predicate = NSPredicate(format: "typeID in %@", missing)
							for price in (try? managedObjectContext.fetch(request)) ?? [] {
								prices[Int(price.typeID)] = price.price
							}
							DispatchQueue.main.async {
								completionHandler(prices)
								lifeTime.finalize()
							}

						}
					}
					else {
						completionHandler(prices)
						lifeTime.finalize()
					}
				}
			}
			else {
				DispatchQueue.main.async {
					completionHandler(prices)
					lifeTime.finalize()
				}
			}
		}
	}

	func marketHistory(typeID: Int, regionID: Int, completionHandler: @escaping (NCCachedResult<[ESI.Market.History]>) -> Void) {
		loadFromCache(forKey: "ESI.Market.History.\(regionID).\(typeID)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.market.listHistoricalMarketStatisticsInRegion(regionID: regionID, typeID: typeID) { result in
				if result.value?.isEmpty == true {
					completion(result, 60)
				}
				else {
					completion(result, 3600.0 * 12)
				}
			}
		})
	}

	func marketOrders(typeID: Int, regionID: Int, completionHandler: @escaping (NCCachedResult<[ESI.Market.Order]>) -> Void) {
		loadFromCache(forKey: "ESI.Market.Order.\(regionID).\(typeID)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.market.listOrdersInRegion(orderType: .all, regionID: regionID, typeID: typeID) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}
	
	func search(_ string: String, categories: [ESI.Search.Categories], strict: Bool = false, completionHandler: @escaping (NCCachedResult<ESI.Search.SearchResult>) -> Void) {
		loadFromCache(forKey: "ESI.Search.SearchResult.\(categories.hashValue).\(string.lowercased().hashValue).\(strict)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.search.search(categories: categories, search: string, strict: strict) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	func searchNames(_ string: String, categories: [ESI.Search.Categories], strict: Bool = false, completionHandler: @escaping ([Int64: NCContact]) -> Void) {
		let lifeTime = NCExtendedLifeTime(self)
		self.search(string, categories: categories) { result in
			switch result {
			case let .success(value):
				let searchResult = value.value
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
					self.contacts(ids: Set(ids.map{Int64($0)}), completionHandler: completionHandler)
				}
				else {
					completionHandler([:])
				}
			case .failure:
				completionHandler([:])
			}
			lifeTime.finalize()
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
								result[ESI.Search.SearchCategories.agent.rawValue] = Dictionary(searchResult.agent?.flatMap(map))
								result[ESI.Search.SearchCategories.alliance.rawValue] = Dictionary(searchResult.alliance?.flatMap(map))
								result[ESI.Search.SearchCategories.character.rawValue] = Dictionary(searchResult.character?.flatMap(map))
								result[ESI.Search.SearchCategories.constellation.rawValue] = Dictionary(searchResult.constellation?.flatMap(map))
								result[ESI.Search.SearchCategories.corporation.rawValue] = Dictionary(searchResult.corporation?.flatMap(map))
								result[ESI.Search.SearchCategories.faction.rawValue] = Dictionary(searchResult.faction?.flatMap(map))
								result[ESI.Search.SearchCategories.inventorytype.rawValue] = Dictionary(searchResult.inventorytype?.flatMap(map))
								result[ESI.Search.SearchCategories.region.rawValue] = Dictionary(searchResult.region?.flatMap(map))
								result[ESI.Search.SearchCategories.solarsystem.rawValue] = Dictionary(searchResult.solarsystem?.flatMap(map))
								result[ESI.Search.SearchCategories.station.rawValue] = Dictionary(searchResult.station?.flatMap(map))
								result[ESI.Search.SearchCategories.wormhole.rawValue] = Dictionary(searchResult.wormhole?.flatMap(map))
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

	func sendMail(body: String, subject: String, recipients: [ESI.Mail.Recipient], completionHandler: @escaping (Result<Int>) -> Void) {
		let mail = ESI.Mail.NewMail()
		mail.body = body
		mail.subject = subject
		mail.recipients = recipients
		self.esi.mail.sendNewMail(characterID: Int(characterID), mail: mail, completionBlock: completionHandler)
	}
	
	func returnMailHeaders(lastMailID: Int64? = nil, labels: [Int64], completionHandler: @escaping (NCCachedResult<[ESI.Mail.Header]>) -> Void) {
		let labels = labels.sorted()
		loadFromCache(forKey: "ESI.Mail.Header.\(labels.hashValue).\(lastMailID ?? 0)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.mail.returnMailHeaders(characterID: Int(self.characterID), labels: labels, lastMailID: lastMailID != nil ? Int(lastMailID!) : nil) { result in
				completion(result, 60)
			}
		})
	}

	func returnMailBody(mailID: Int64, completionHandler: @escaping (NCCachedResult<ESI.Mail.MailBody>) -> Void) {
		loadFromCache(forKey: "ESI.Mail.MailBody.\(mailID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.mail.returnMail(characterID: Int(self.characterID), mailID: Int(mailID)) { result in
				completion(result, 3600.0 * 48)
			}
		})
	}

	func returnMailingLists(completionHandler: @escaping (NCCachedResult<[ESI.Mail.Subscription]>) -> Void) {
		loadFromCache(forKey: "ESI.Mail.Subscription", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.mail.returnMailingListSubscriptions(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}
	
	func mailLabels(completionHandler: @escaping (NCCachedResult<ESI.Mail.MailLabelsAndUnreadCounts>) -> Void) {
		loadFromCache(forKey: "ESI.Mail.MailLabelsAndUnreadCounts", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.mail.getMailLabelsAndUnreadCounts(characterID: Int(self.characterID)) { result in
				completion(result, 60*10)
			}
		})
	}
	
	func calendarEvents(completionHandler: @escaping (NCCachedResult<[ESI.Calendar.Summary]>) -> Void) {
		loadFromCache(forKey: "ESI.Calendar.Summary", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.calendar.listCalendarEventSummaries(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0 * 1)
			}
		})
	}

	func calendarEventDetails(eventID: Int64, completionHandler: @escaping (NCCachedResult<ESI.Calendar.Event>) -> Void) {
		loadFromCache(forKey: "ESI.Calendar.Event.\(eventID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.calendar.getAnEvent(characterID: Int(self.characterID), eventID: Int(eventID)) { result in
				completion(result, 3600.0 * 48)
			}
		})
	}

	
	func markRead(mail: ESI.Mail.Header, completionHandler: @escaping (Result<String>) -> Void) {
		guard let mailID = mail.mailID else {
			completionHandler(.failure(NCDataManagerError.internalError))
			return
		}
		
		let contents = ESI.Mail.UpdateContents()
		contents.read = true
		contents.labels = mail.labels
		self.esi.mail.updateMetadataAboutMail(characterID: Int(self.characterID), contents: contents, mailID: Int(mailID), completionBlock: completionHandler)
	}
	
	func delete(mailID: Int64, completionHandler: @escaping (Result<String>) -> Void) {
		self.esi.mail.deleteMail(characterID: Int(self.characterID), mailID: Int(mailID), completionBlock: completionHandler)
	}

	
	private static var invalidIDs = Set<Int64>()
	
	func contacts(ids: Set<Int64>, completionHandler: @escaping ([Int64: NCContact]) -> Void) {
		let ids = ids.subtracting(NCDataManager.invalidIDs)
		var contacts: Set<Int64> = Set()
		
		func finish() {
			DispatchQueue.main.async {
				guard let context = NCCache.sharedCache?.viewContext else {
					completionHandler([:])
					return
				}
				
				let request = NSFetchRequest<NCContact>(entityName: "Contact")
				request.predicate = NSPredicate(format: "contactID in %@", ids)
				
				var result: [Int64: NCContact] = [:]
				(try? context.fetch(request))?.forEach {
					result[$0.contactID] = $0
				}

				completionHandler(result)
			}
		}
		
		NCCache.sharedCache?.performBackgroundTask { managedObjectContext in
			
//			let ids = ids.sorted()
			let request = NSFetchRequest<NSDictionary>(entityName: "Contact")
			request.predicate = NSPredicate(format: "contactID in %@", ids)
			request.resultType = .dictionaryResultType
			request.propertiesToFetch = [NSEntityDescription.entity(forEntityName: "Contact", in: managedObjectContext)!.propertiesByName["contactID"]!]
			
			contacts = Set((try? managedObjectContext.fetch(request))?.flatMap {$0["contactID"] as? Int64} ?? [])
			
			var missing = ids.subtracting(contacts)
			
			if !missing.isEmpty {
				var mailingLists: [ESI.Mail.Subscription] = []
				var names: [ESI.Universe.Name] = []
				let dispatchGroup = DispatchGroup()
				
				
				dispatchGroup.enter()
				self.universeNames(ids: missing) { result in
					switch result {
					case let .success(value, _):
						names = value
						missing.subtract(Set(value.map {Int64($0.id)}))
					case let .failure(error):
						if (error as? AFError)?.responseCode == 404 {
							NCDataManager.invalidIDs.formUnion(missing)
						}
					}
					
					if !missing.isEmpty {
						dispatchGroup.enter()
						self.returnMailingLists { result in
							switch result {
							case let .success(value, _):
								mailingLists = value.filter {ids.contains(Int64($0.mailingListID))}
							case .failure:
								break
							}
							dispatchGroup.leave()
						}
					}

					dispatchGroup.leave()
				}
				
				dispatchGroup.notify(queue: .main) {
					NCCache.sharedCache?.performBackgroundTask { managedObjectContext in
						managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
						
						var result = names.map{($0.id, $0.name, $0.category.rawValue)}
						result.append(contentsOf: mailingLists.map {($0.mailingListID, $0.name, ESI.Mail.Recipient.RecipientType.mailingList.rawValue)})
						
						for name in result {
							let contact = NCContact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: managedObjectContext)!, insertInto: managedObjectContext)
							contact.contactID = Int64(name.0)
							contact.name = name.1
							contact.type = name.2
							
							contacts.insert(contact.contactID)
//							contacts[contact.contactID] = contact
						}
						if managedObjectContext.hasChanges {
							try! managedObjectContext.save()
						}
						finish()
					}
				}

			}
			else {
				finish()
			}
		}
	}
	
	
	func marketPrices(completionHandler: @escaping (NCCachedResult<[ESI.Market.Price]>) -> Void) {
		loadFromCache(forKey: "ESI.Market.Price", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.market.listMarketPrices { result in
				completion(result, 3600.0 * 12)
			}
		})
	}
	
	func assets(completionHandler: @escaping (NCCachedResult<[ESI.Assets.Asset]>) -> Void) {
		loadFromCache(forKey: "ESI.Assets.Asset", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.assets.getCharacterAssets(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0 * 1)
			}
		})
	}
	
	func blueprints(completionHandler: @escaping (NCCachedResult<[ESI.Character.Blueprint]>) -> Void) {
		loadFromCache(forKey: "ESI.Character.Blueprint", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
            self.esi.character.getBlueprints(characterID: Int(self.characterID)) { result in
                completion(result, 3600.0 * 1)
            }
		})
	}

	func industryJobs(completionHandler: @escaping (NCCachedResult<[ESI.Industry.Job]>) -> Void) {
		loadFromCache(forKey: "ESI.Industry.Job", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.industry.listCharacterIndustryJobs(characterID: Int(self.characterID), includeCompleted: true) { result in
				completion(result, 3600.0 * 1)
			}
		})
	}

	func marketOrders(completionHandler: @escaping (NCCachedResult<[ESI.Market.CharacterOrder]>) -> Void) {
		loadFromCache(forKey: "ESI.Market.CharacterOrder", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.market.listOrdersFromCharacter(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0 * 1)
			}
		})
	}

	func walletJournal(completionHandler: @escaping (NCCachedResult<[ESI.Wallet.WalletJournalItem]>) -> Void) {
		loadFromCache(forKey: "ESI.Wallet.WalletJournalItem", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.wallet.getCharacterWalletJournal(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0 * 1)
			}
		})
	}

	func walletTransactions(completionHandler: @escaping (NCCachedResult<[ESI.Wallet.Transaction]>) -> Void) {
		loadFromCache(forKey: "ESI.Wallet.Transaction", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.wallet.getWalletTransactions(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0 * 1)
			}
		})
	}

//	func refTypes(completionHandler: @escaping (NCCachedResult<EVE.Eve.RefTypes>) -> Void) {
//		loadFromCache(forKey: "EVE.Eve.RefTypes", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
//			self.eve.eve.refTypes { result in
//				completion(result, 3600.0 * 24 * 7)
//			}
//		})
//	}

	func contracts(completionHandler: @escaping (NCCachedResult<[ESI.Contracts.Contract]>) -> Void) {
		loadFromCache(forKey: "ESI.Contracts.Contract", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.contracts.getContracts(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0 * 1)
			}
		})
	}

	func contractItems(contractID: Int64, completionHandler: @escaping (NCCachedResult<[ESI.Contracts.Item]>) -> Void) {
		loadFromCache(forKey: "ESI.Contracts.Item.\(contractID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.contracts.getContractItems(characterID: Int(self.characterID), contractID: Int(contractID)) { result in
				if let error = result.error as? AFError, error.responseCode == 404 {
					completion(.success([]), 3600.0 * 24)
				}
				else {
					completion(result, 3600.0 * 24)
				}
			}
		})
	}

	func contractBids(contractID: Int64, completionHandler: @escaping (NCCachedResult<[ESI.Contracts.Bid]>) -> Void) {
		loadFromCache(forKey: "ESI.Contracts.Bid.\(contractID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.contracts.getContractBids(characterID: Int(self.characterID), contractID: Int(contractID)) { result in
				if let error = result.error as? AFError, error.responseCode == 404 {
					completion(.success([]), 3600.0 * 24)
				}
				else {
					completion(result, 3600.0 * 24)
				}
			}
		})
	}


	func incursions(completionHandler: @escaping (NCCachedResult<[ESI.Incursions.Incursion]>) -> Void) {
		loadFromCache(forKey: "ESI.Incursions.Incursion", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.incursions.listIncursions { result in
				completion(result, 600)
			}
		})
	}
	
	func colonies(completionHandler: @escaping (NCCachedResult<[ESI.PlanetaryInteraction.Colony]>) -> Void) {
		loadFromCache(forKey: "ESI.PlanetaryInteraction.Colony", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.planetaryInteraction.getColonies(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0 * 1)
			}
		})
	}
	
	func colonyLayout(planetID: Int, completionHandler: @escaping (NCCachedResult<ESI.PlanetaryInteraction.ColonyLayout>) -> Void) {
		loadFromCache(forKey: "ESI.PlanetaryInteraction.ColonyLayout.\(planetID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.planetaryInteraction.getColonyLayout(characterID: Int(self.characterID), planetID: planetID) { result in
				completion(result, 3600.0 * 1)
			}
		})
	}

	func killmails(maxKillID: Int64? = nil, completionHandler: @escaping (NCCachedResult<[ESI.Killmails.Recent]>) -> Void) {
		loadFromCache(forKey: "ESI.Killmails.Recent.\(maxKillID ?? 0)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.killmails.getCharacterKillsAndLosses(characterID: Int(self.characterID), maxKillID: maxKillID != nil ? Int(maxKillID!) : nil) { result in
				completion(result, maxKillID == nil ? 60 * 2 : 3600 * 24)
			}
		})
	}
	
	func killmailInfo(killmailHash: String, killmailID: Int64, completionHandler: @escaping (NCCachedResult<ESI.Killmails.Killmail>) -> Void) {
		loadFromCache(forKey: "ESI.KillMails.Killmail.\(killmailID).\(killmailHash)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.killmails.getSingleKillmail(killmailHash: killmailHash, killmailID: Int(killmailID)) { result in
				completion(result, 3600.0 * 48)
			}
		})
	}
	
	func zKillmails(filter: [ZKillboard.Filter], page: Int, completionHandler: @escaping (NCCachedResult<[ZKillboard.Killmail]>) -> Void) {
		let key = filter.map{$0.value}.sorted().joined(separator: "/")
		loadFromCache(forKey: "ZKillboard.Killmail.\(key)/\(page)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.zKillboard.kills(filter: filter, page: page) { result in
				completion(result, 600)
			}
		})
	}
	
	func rss(url: URL, completionHandler: @escaping (NCCachedResult<RSS.Feed>) -> Void) {
		loadFromCache(forKey: "RSS.Feed.\(url.absoluteString)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			Alamofire.request(url, method: .get).validate().responseRSS { (response: DataResponse<RSS.Feed>) in
				completion(response.result, 600)
			}
		})
	}

	
	func fittings(completionHandler: @escaping (NCCachedResult<[ESI.Fittings.Fitting]>) -> Void) {
		loadFromCache(forKey: "ESI.Fittings.Fitting", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.fittings.getFittings(characterID: Int(self.characterID)) { result in
				completion(result, 300)
			}
		})
	}
	
	func deleteFitting(fittingID: Int, completionHandler: @escaping (Result<String>) -> Void) {
		self.esi.fittings.deleteFitting(characterID: Int(self.characterID), fittingID: fittingID, completionBlock: completionHandler)
	}
	
	func createFitting(fitting: ESI.Fittings.MutableFitting, completionHandler: @escaping (Result<ESI.Fittings.CreateFittingResult>) -> Void) {
		self.esi.fittings.createFitting(characterID: Int(self.characterID), fitting: fitting, completionBlock: completionHandler)
	}
	
	func serverStatus(completionHandler: @escaping (NCCachedResult<ESI.Status.ServerStatus>) -> Void) {
		loadFromCache(forKey: "ESI.Status.ServerStatus", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.status.retrieveTheUptimeAndPlayerCounts { result in
				completion(result, 600)
			}
		})
	}
	
	func loyaltyPoints(completionHandler: @escaping (NCCachedResult<[ESI.Loyalty.Point]>) -> Void) {

		loadFromCache(forKey: "ESI.Loyalty.Point", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.loyalty.getLoyaltyPoints(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0 * 1)
			}
		})
	}
	
	func loyaltyStoreOffers(corporationID: Int64, completionHandler: @escaping (NCCachedResult<[ESI.Loyalty.Offer]>) -> Void) {
		loadFromCache(forKey: "ESI.Loyalty.Offer.\(corporationID)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.loyalty.listLoyaltyStoreOffers(corporationID: Int(corporationID)) { result in
				completion(result, 3600.0 * 24)
			}
		})
	}

	//MARK: Private
	
	private var completionHandlers: [String: [(Any?, NCCacheRecord?, Error?) -> Void]] = [:]
	
	private func loadFromCache<T> (forKey key: String,
	                           account: String?,
	                           cachePolicy:URLRequest.CachePolicy,
	                           completionHandler: @escaping (NCCachedResult<T>) -> Void,
	                           elseLoad loader: @escaping (@escaping NCLoaderCompletion<T>) -> Void) {
		
		guard let cache = NCCache.sharedCache else {
			completionHandler(.failure(NCDataManagerError.internalError))
			return
		}
		
		let completionHandlerKey = key + (account ?? "")
		func finish(value: T?, record: NCCacheRecord?, error: Error?) {
			let array = completionHandlers[completionHandlerKey]
			completionHandlers[completionHandlerKey] = nil
			array?.forEach {$0(value, record, error)}
		}
		
		let completion = {(value: Any?, record: NCCacheRecord?, error: Error?) in
			if let value = value as? T {
				completionHandler(.success(value: value, cacheRecord: record))
			}
			else {
				completionHandler(.failure(error ?? NCDataManagerError.invalidResponse))
			}
		}
		
		var array = completionHandlers[completionHandlerKey] ?? []
		if !array.isEmpty {
			array.append(completion)
			completionHandlers[completionHandlerKey] = array
			return
		}
		else {
			completionHandlers[completionHandlerKey] = [completion]
		}
		
		let progress = Progress(totalUnitCount: 1)
		let lifeTime = NCExtendedLifeTime(self)

		switch cachePolicy {
		case .reloadIgnoringLocalCacheData:
			progress.becomeCurrent(withPendingUnitCount: 1)
			loader { (result, cacheTime) in
				switch (result) {
				case let .success(value):
					cache.store(value as? NSObject, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { cacheRecord in
//						completionHandler(.success(value: value, cacheRecord: cacheRecord))
						finish(value: value, record: cacheRecord, error: nil)
					}
				case let .failure(error):
//					completionHandler(.failure(error))
					finish(value: nil, record: nil, error: error)
				}
				lifeTime.finalize()
			}
			progress.resignCurrent()
			
		case .returnCacheDataElseLoad:
			cache.performBackgroundTask { (managedObjectContext) in
				let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)))?.last
				let object = record?.data?.data as? T
				
				DispatchQueue.main.async {
					if let object = object {
						progress.completedUnitCount += 1
//						completionHandler(.success(value: object, cacheRecord: (try? NCCache.sharedCache?.viewContext.existingObject(with: record!.objectID)) as? NCCacheRecord))
						finish(value: object, record: (try? NCCache.sharedCache?.viewContext.existingObject(with: record!.objectID)) as? NCCacheRecord, error: nil)
						lifeTime.finalize()
					}
					else {
						progress.becomeCurrent(withPendingUnitCount: 1)
						loader { (result, cacheTime) in
							switch (result) {
							case let .success(value):
								cache.store(value as? NSObject, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { cacheRecord in
//									completionHandler(.success(value: value, cacheRecord: cacheRecord))
									finish(value: value, record: cacheRecord, error: nil)
								}
							case let .failure(error):
//								completionHandler(.failure(error))
								finish(value: nil, record: nil, error: error)
							}
							lifeTime.finalize()
						}

						progress.resignCurrent()
					}
				}
			}
		case .returnCacheDataDontLoad:
			cache.performBackgroundTask { (managedObjectContext) in
				let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)))?.last
				let object = record?.data?.data as? T
				
				DispatchQueue.main.async {
					if let object = object {
						progress.completedUnitCount += 1
//						completionHandler(.success(value: object, cacheRecord: (try? NCCache.sharedCache?.viewContext.existingObject(with: record!.objectID)) as? NCCacheRecord))
						finish(value: object, record: (try? NCCache.sharedCache?.viewContext.existingObject(with: record!.objectID)) as? NCCacheRecord, error: nil)
					}
					else {
//						completionHandler(.failure(NCDataManagerError.noCacheData))
						finish(value: nil, record: nil, error: NCDataManagerError.noCacheData)
					}
					lifeTime.finalize()
				}
			}
		default:
			cache.performBackgroundTask { (managedObjectContext) in
				let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)))?.last
				let object = record?.data?.data as? T
				let expired = record?.isExpired ?? true
				DispatchQueue.main.async {
					if let object = object {
						progress.completedUnitCount += 1
//						completionHandler(.success(value: object, cacheRecord: (try? NCCache.sharedCache?.viewContext.existingObject(with: record!.objectID)) as? NCCacheRecord))
						finish(value: object, record: (try? NCCache.sharedCache?.viewContext.existingObject(with: record!.objectID)) as? NCCacheRecord, error: nil)
						if expired {
							loader { (result, cacheTime) in
								switch (result) {
								case let .success(value):
									cache.store(value as? NSObject, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { _ in
									}
								default:
									break
								}
								lifeTime.finalize()
							}
						}
					}
					else {
						progress.becomeCurrent(withPendingUnitCount: 1)
						loader { (result, cacheTime) in
							switch (result) {
							case let .success(value):
								cache.store(value as? NSObject, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { cacheRecord in
//									completionHandler(.success(value: value, cacheRecord: cacheRecord))
									finish(value: value, record: cacheRecord, error: nil)
								}
							case let .failure(error):
//								completionHandler(.failure(error))
								finish(value: nil, record: nil, error: error)
							}
							lifeTime.finalize()
						}
						progress.resignCurrent()
					}
				}
			}
		}
	}
	
}
