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


typealias NCLoaderCompletion<T> = (_ result: Result<T>, _ cacheTime: TimeInterval) -> Void


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
		return OAuth2Retrier(token: token, clientID: ESClientID, secretKey: ESSecretKey)
	}()
	
	lazy var esi: ESI = {
		if let token = self.token {
			return ESI(token: token, clientID: ESClientID, secretKey: ESSecretKey, server: .tranquility, cachePolicy: self.cachePolicy, retrier: self.retrier)
		}
		else {
			return ESI(cachePolicy: self.cachePolicy)
		}
	}()

	lazy var eve: EVE = {
		if let token = self.token {
			return EVE(token: token, clientID: ESClientID, secretKey: ESSecretKey, server: .tranquility, cachePolicy: self.cachePolicy, retrier: self.retrier)
		}
		else {
			return EVE(cachePolicy: self.cachePolicy)
		}
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
			self.token = acc.token
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

	func accountStatus(completionHandler: @escaping (NCCachedResult<EVE.Account.AccountStatus>) -> Void) {
		loadFromCache(forKey: "EVE.Account.AccountStatus", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.eve.account.accountStatus { result in
				completion(result, 3600.0)
			}
		})
	}

	
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
	
	
	func wallets(completionHandler: @escaping (NCCachedResult<[ESI.Wallet.Balance]>) -> Void) {
		loadFromCache(forKey: "ESI.Wallet.Balance", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.wallet.listWalletsAndBalances(characterID: Int(self.characterID)) { result in
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
	
	func clones(completionHandler: @escaping (NCCachedResult<EVE.Char.Clones>) -> Void) {
		loadFromCache(forKey: "EVE.Char.Clones", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.eve.char.clones { result in
				completion(result, 3600.0)
			}
//			self.esi.clones.getClones(characterID: Int(self.characterID)) { result in
//				completion(result, 3600.0)
//			}
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

	func locations(ids: Set<Int64>, completionHandler: @escaping ([Int64: NCLocation]) -> Void) {
		var locations = [Int64: NCLocation]()
		var missing = Set<Int64>()
		var structures = Set<Int64>()
		
		for id in ids {
			if id > Int64(Int32.max) {
				structures.insert(id)
			}
			else if (66000000 < id && id < 66014933) { //staStations
				if let station = NCDatabase.sharedDatabase?.staStations[Int(id) - 6000001] {
					locations[id] = NCLocation(station)
				}
				else {
					missing.insert(id)
				}
			}
			else if (60000000 < id && id < 61000000) { //staStations
				if let station = NCDatabase.sharedDatabase?.staStations[Int(id)] {
					locations[id] = NCLocation(station)
				}
				else {
					missing.insert(id)
				}
			}
			else if let int = Int(exactly: id) { //mapDenormalize
				
				if let mapDenormalize = NCDatabase.sharedDatabase?.mapDenormalize[int] {
					locations[id] = NCLocation(mapDenormalize)
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
		if missing.count > 0 {
			dispatchGroup.enter()
			self.universeNames(ids: missing) { result in
				let _ = self
				switch result {
				case let .success(value, _):
					for name in value {
						if let location = NCLocation(name) {
							locations[Int64(name.id)] = location
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
					locations[id] = NCLocation(value)
				case .failure:
					break
				}
				dispatchGroup.leave()
			}
		}
		
		dispatchGroup.notify(queue: .main) {
			completionHandler(locations)
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

	
	func updateMarketPrices(completionHandler: ((_ isUpdated: Bool) -> Void)?) {
		NCCache.sharedCache?.performBackgroundTask{ managedObjectContext in
			let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: "ESMarketPrices", account: nil)))?.last
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
							}
						}
					default:
						completionHandler?(false)
					}
				}
			}
			else {
				DispatchQueue.main.async {
					completionHandler?(false)
				}
			}
		}
	}
	
	func prices(typeIDs: [Int], completionHandler: @escaping ([Int: Double]) -> Void) {
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
							}

						}
					}
					else {
						completionHandler(prices)
					}
				}
			}
			else {
				DispatchQueue.main.async {
					completionHandler(prices)
				}
			}
		}
	}

	func marketHistory(typeID: Int, regionID: Int, completionHandler: @escaping (NCCachedResult<[ESI.Market.History]>) -> Void) {
		loadFromCache(forKey: "ESI.Market.History.\(regionID).\(typeID)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.market.listHistoricalMarketStatisticsInRegion(regionID: regionID, typeID: typeID) { result in
				completion(result, 3600.0 * 12)
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
	
	func search(_ string: String, categories: [ESI.Search.SearchCategories], strict: Bool = false, completionHandler: @escaping (NCCachedResult<ESI.Search.SearchResult>) -> Void) {
		loadFromCache(forKey: "ESI.Search.SearchResult.\(categories.hashValue).\(string.lowercased().hashValue).\(strict)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.search.search(categories: categories, search: string, strict: strict) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	func searchNames(_ string: String, categories: [ESI.Search.SearchCategories], strict: Bool = false, completionHandler: @escaping ([Int64: NCContact]) -> Void) {
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
				ids.formUnion(searchResult.inventorytype ?? [])
				ids.formUnion(searchResult.region ?? [])
				ids.formUnion(searchResult.solarsystem ?? [])
				ids.formUnion(searchResult.station ?? [])
				ids.formUnion(searchResult.wormhole ?? [])
				
				if ids.count > 0 {
					self.contacts(ids: Set(ids.map{Int64($0)}), completionHandler: completionHandler)
				}
				else {
					completionHandler([:])
				}
			case .failure:
				completionHandler([:])
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
	
	func returnMailHeaders(lastMailID: Int64? = nil, completionHandler: @escaping (NCCachedResult<[ESI.Mail.Header]>) -> Void) {
		loadFromCache(forKey: "ESI.Mail.Header.\(lastMailID ?? 0)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.mail.returnMailHeaders(characterID: Int(self.characterID), lastMailID: lastMailID != nil ? Int(lastMailID!) : nil) { result in
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

	/*func fetchMail(completionHandler: @escaping (Result<[NSManagedObjectID]>) -> Void) {
		guard let cache = NCCache.sharedCache else {
			completionHandler(.failure(NCDataManagerError.internalError))
			return
		}

//		var headers: [ESI.Mail.Header] = []
//		var contacts: [Int64: NSManagedObjectID] = [:]
		let characterID = self.characterID

		cache.performBackgroundTask { managedObjectContext in
			let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: "ESI.Mail.Header.0", account: self.account)))?.first
			let isExpired = record?.isExpired ?? true
			
			if isExpired {
				let request = NSFetchRequest<NSDictionary>(entityName: "Mail")
				request.predicate = NSPredicate(format: "characterID == %qi", characterID)
				request.propertiesToFetch = [NSExpressionDescription(name: "mailID", resultType: .integer64AttributeType, expression: NSExpression(format: "max(mailID)"))]
				request.resultType = .dictionaryResultType
				let lastMailID = (try? managedObjectContext.fetch(request))?.first?["mailID"] as? Int64 ?? 0

				func fetch(from: Int64?) {
					
					self.returnMailHeaders(lastMailID: from) { result in
						switch result {
						case let .success(value, _):
							let headers = value
							
							var ids = [Int64]()
							for mail in headers {
								ids.append(contentsOf: mail.recipients?.flatMap {$0.recipientType != .mailingList ? Int64($0.recipientID) : nil} ?? [])
								if let from = mail.from {
									ids.append(Int64(from))
								}
							}
							if ids.count > 0 {
								self.contacts(ids: ids) { result in
									process(headers: headers, contacts: result)
								}
							}
							else {
								process(headers: headers, contacts: [:])
							}
							
							if let minMailID = headers.map ({$0.mailID ?? 0}).min(), value.count > 0 && minMailID > lastMailID {
								fetch(from: minMailID)
							}
							
						case let .failure(error):
							completionHandler(.failure(error))
						}
					}
				}
				fetch(from: nil)
				
			}
			else {
				DispatchQueue.main.async {
					completionHandler(.success([]))
				}
				
			}
		}
		
		func process(headers: [ESI.Mail.Header], contacts: [Int64: NSManagedObjectID]) {
			cache.performBackgroundTask { managedObjectContext in
				managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
				var newMails: [NCMail] = []
				
				for header in headers {
					guard let mailID = header.mailID else {continue}
					guard let from = header.from else {continue}
					let labels = header.labels?.sorted(by: <) ?? []
					let request = NSFetchRequest<NCMail>(entityName: "Mail")
					let recipients = header.recipients?.flatMap {contacts[Int64($0.recipientID)]}.flatMap {(try? managedObjectContext.existingObject(with: $0)) as? NCContact}
					let to = Set(recipients ?? [])
					
					
					request.predicate = NSPredicate(format: "mailID == %qi", header.mailID ?? 0)
					request.fetchLimit = 1
					let mail = (try? managedObjectContext.fetch(request))?.first ?? {
						let mail = NCMail(entity: NSEntityDescription.entity(forEntityName: "Mail", in: managedObjectContext)!, insertInto: managedObjectContext)
						mail.characterID = characterID
						mail.mailID = mailID
						mail.labels = labels
						mail.timestamp = header.timestamp as NSDate?
						mail.subject = header.subject
						
						if characterID == Int64(header.from ?? 0) {
							mail.folder = Int32(NCMail.Folder.sent.rawValue)
						}
						else if header.recipients?.first(where: {Int64($0.recipientID) == characterID}) != nil {
							mail.folder = Int32(NCMail.Folder.inbox.rawValue)
						}
						else if header.recipients?.first(where: {$0.recipientType == .corporation}) != nil {
							mail.folder = Int32(NCMail.Folder.corporation.rawValue)
						}
						else if header.recipients?.first(where: {$0.recipientType == .alliance}) != nil {
							mail.folder = Int32(NCMail.Folder.alliance.rawValue)
						}
						else if header.recipients?.first(where: {$0.recipientType == .mailingList}) != nil {
							mail.folder = Int32(NCMail.Folder.mailingList.rawValue)
						}
						else {
							mail.folder = Int32(NCMail.Folder.unknown.rawValue)
						}

						
						newMails.append(mail)
						return mail
					}()

					if let fromID = contacts[Int64(from)], let contact = try? managedObjectContext.existingObject(with: fromID) as? NCContact, mail.from != contact {
						mail.from = contact
					}
					mail.isRead = mail.isRead || (header.isRead ?? false)
					if mail.to != to as NSSet {
						mail.to = to as NSSet
					}
				}
				
				if (managedObjectContext.hasChanges) {
					try? managedObjectContext.save()
				}
				
				DispatchQueue.main.async {
					completionHandler(.success(newMails.map{$0.objectID}))
				}
			}
		}
	}*/
	
	private static var invalidIDs = Set<Int64>()
	
	func contacts(ids: Set<Int64>, completionHandler: @escaping ([Int64: NCContact]) -> Void) {
		let ids = ids.subtracting(NCDataManager.invalidIDs)
		var contacts: [Int64: NCContact] = [:]
		
		func finish() {
			DispatchQueue.main.async {
				let context = NCCache.sharedCache?.viewContext
				
				var result: [Int64: NCContact] = [:]
				for (key, value) in contacts {
					guard let object = (try? context?.existingObject(with: value.objectID)) as? NCContact else {continue}
					result[key] = object
				}
				completionHandler(result)
			}
		}
		
		NCCache.sharedCache?.performBackgroundTask { managedObjectContext in
			
//			let ids = ids.sorted()
			let request = NSFetchRequest<NCContact>(entityName: "Contact")
			request.predicate = NSPredicate(format: "contactID in %@", ids)
			
			
			for contact in (try? managedObjectContext.fetch(request)) ?? [] {
				contacts[contact.contactID] = contact
			}

			var missing = Set(ids.filter {return contacts[$0] == nil})
			
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
						
						let request = NSFetchRequest<NCContact>(entityName: "Contact")
						
						var result = names.map{($0.id, $0.name, $0.category.rawValue)}
						result.append(contentsOf: mailingLists.map {($0.mailingListID, $0.name, ESI.Mail.Recipient.RecipientType.mailingList.rawValue)})
						
						
						for name in result {
							request.predicate = NSPredicate(format: "contactID == %qi", name.0)
							let contact = (try? managedObjectContext.fetch(request))?.first ?? {
								let contact = NCContact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: managedObjectContext)!, insertInto: managedObjectContext)
								contact.contactID = Int64(name.0)
								contact.name = name.1
								contact.type = name.2
								return contact
								}()
							contacts[contact.contactID] = contact
						}
						if managedObjectContext.hasChanges {
							try? managedObjectContext.save()
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
		loadFromCache(forKey: "ESI.Market.Price", account: nil, cachePolicy: .reloadIgnoringLocalCacheData, completionHandler: completionHandler, elseLoad: { completion in
			self.esi.market.listMarketPrices { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	//MARK: Private
	
	private func loadFromCache<T> (forKey key: String,
	                           account: String?,
	                           cachePolicy:URLRequest.CachePolicy,
	                           completionHandler: @escaping (NCCachedResult<T>) -> Void,
	                           elseLoad loader: @escaping (@escaping NCLoaderCompletion<T>) -> Void) {

		guard let cache = NCCache.sharedCache else {
			completionHandler(.failure(NCDataManagerError.internalError))
			return
		}
		
		let progress = Progress(totalUnitCount: 1)
		
		switch cachePolicy {
		case .reloadIgnoringLocalCacheData:
			progress.becomeCurrent(withPendingUnitCount: 1)
			loader { (result, cacheTime) in
				switch (result) {
				case let .success(value):
					cache.store(value as? NSSecureCoding, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { cacheRecord in
						completionHandler(.success(value: value, cacheRecord: cacheRecord))
					}
				case let .failure(error):
					/*switch error {
					case ESError.forbidden:
						break
					default:
						break
					}*/
					completionHandler(.failure(error))
					break
				}
			}
			progress.resignCurrent()
			
		case .returnCacheDataElseLoad:
			cache.performBackgroundTask { (managedObjectContext) in
				let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)))?.last
				let object = record?.data?.data as? T
				
				DispatchQueue.main.async {
					if let object = object {
						progress.completedUnitCount += 1
						completionHandler(.success(value: object, cacheRecord: (try? NCCache.sharedCache?.viewContext.existingObject(with: record!.objectID)) as? NCCacheRecord))
					}
					else {
						progress.becomeCurrent(withPendingUnitCount: 1)
						loader { (result, cacheTime) in
							switch (result) {
							case let .success(value):
								cache.store(value as? NSSecureCoding, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { cacheRecord in
									completionHandler(.success(value: value, cacheRecord: cacheRecord))
								}
							case let .failure(error):
								completionHandler(.failure(error))
								break
							}
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
						completionHandler(.success(value: object, cacheRecord: (try? NCCache.sharedCache?.viewContext.existingObject(with: record!.objectID)) as? NCCacheRecord))
					}
					else {
						completionHandler(.failure(NCDataManagerError.noCacheData))
					}
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
						completionHandler(.success(value: object, cacheRecord: (try? NCCache.sharedCache?.viewContext.existingObject(with: record!.objectID)) as? NCCacheRecord))
						if expired {
							loader { (result, cacheTime) in
								let _ = self
								switch (result) {
								case let .success(value):
									cache.store(value as? NSSecureCoding, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { _ in
										let _ = self
									}
								default:
									break
								}
							}
						}
					}
					else {
						progress.becomeCurrent(withPendingUnitCount: 1)
						loader { (result, cacheTime) in
							switch (result) {
							case let .success(value):
								cache.store(value as? NSSecureCoding, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { cacheRecord in
									completionHandler(.success(value: value, cacheRecord: cacheRecord))
									let _ = self
								}
							case let .failure(error):
								completionHandler(.failure(error))
								let _ = self
								break
							}
						}
						progress.resignCurrent()
					}
				}
			}
			break
		}
	}
	
}
