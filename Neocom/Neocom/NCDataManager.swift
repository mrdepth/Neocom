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

enum NCResult<T> {
	case success(value: T, cacheRecordID: NSManagedObjectID)
	case failure(Error)
}

typealias NCLoaderCompletion<T> = (_ result: Result<T>, _ cacheTime: TimeInterval) -> Void


class NCDataManager {
	enum NCDataManagerError: Error {
		case internalError
		case invalidResponse
		case noCacheData
	}
	let account: String?
	let token: OAuth2Token?
	let cachePolicy: URLRequest.CachePolicy
	var observer: NSObjectProtocol?
	lazy var api: ESAPI = {
		if let token = self.token {
			return ESAPI(token: token, clientID: ESClientID, secretKey: ESSecretKey, cachePolicy: self.cachePolicy)
		}
		else {
			return ESAPI(cachePolicy: self.cachePolicy)
		}
	}()
	
	init(account: NCAccount?, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
		if let account = account {
			self.account = String(account.characterID)
			self.token = account.token
		}
		else {
			self.account = nil
			self.token = nil
		}
		self.cachePolicy = cachePolicy
	}
	
	deinit {
		if let observer = observer {
			NotificationCenter.default.removeObserver(observer)
		}
	}
	
	func character(completionHandler: @escaping (NCResult<ESCharacter>) -> Void) {
		loadFromCache(forKey: "ESCharacter", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func corporation(corporationID: Int64, completionHandler: @escaping (NCResult<ESCorporation>) -> Void) {
		loadFromCache(forKey: "ESCoproration.\(corporationID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.corporation(corporationID: corporationID) { result in
				completion(result, 3600.0)
			}
		})
	}

	func alliance(allianceID: Int64, completionHandler: @escaping (NCResult<ESAlliance>) -> Void) {
		loadFromCache(forKey: "ESAlliance.\(allianceID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.alliance(allianceID: allianceID) { result in
				completion(result, 3600.0)
			}
		})
	}

	func skillQueue(completionHandler: @escaping (NCResult<[ESSkillQueueItem]>) -> Void) {
		loadFromCache(forKey: "ESSkillQueue", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character.skillQueue { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func skills(completionHandler: @escaping (NCResult<ESSkills>) -> Void) {
		loadFromCache(forKey: "ESSkills", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character.skills { result in
				completion(result, 3600.0)
			}
		})
	}
	
	
	func wallets(completionHandler: @escaping (NCResult<[ESWallet]>) -> Void) {
		loadFromCache(forKey: "ESWallets", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character.wallets { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func characterLocation(completionHandler: @escaping (NCResult<ESCharacterLocation>) -> Void) {
		loadFromCache(forKey: "ESCharacterLocation", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character.location { result in
				completion(result, 3600.0)
			}
		})
	}

	func characterShip(completionHandler: @escaping (NCResult<ESCharacterShip>) -> Void) {
		loadFromCache(forKey: "ESShip", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character.ship { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func clones(completionHandler: @escaping (NCResult<ESClones>) -> Void) {
		loadFromCache(forKey: "ESClones", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.clones { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func image(characterID: Int64, dimension: Int, completionHandler: @escaping (NCResult<UIImage>) -> Void) {
		loadFromCache(forKey: "image.character.\(characterID).\(dimension)", account: nil, cachePolicy: cachePolicy, completionHandler: { (result: NCResult<Data>) in
			switch result {
			case let .success(value: value, cacheRecordID: recordID):
				if let image = UIImage(data: value, scale: UIScreen.main.scale) {
					completionHandler(.success(value: image, cacheRecordID: recordID))
				}
				else {
					completionHandler(.failure(NCDataManagerError.invalidResponse))
				}
			case let .failure(error):
				completionHandler(.failure(error))
			}
		}, elseLoad: { completion in
			self.api.image(characterID: characterID, dimension: dimension * Int(UIScreen.main.scale)) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func image(corporationID: Int64, dimension: Int, completionHandler: @escaping (NCResult<UIImage>) -> Void) {
		loadFromCache(forKey: "image.corporation.\(corporationID).\(dimension)", account: nil, cachePolicy: cachePolicy, completionHandler: { (result: NCResult<Data>) in
			switch result {
			case let .success(value: value, cacheRecordID: recordID):
				if let image = UIImage(data: value, scale: UIScreen.main.scale) {
					completionHandler(.success(value: image, cacheRecordID: recordID))
				}
				else {
					completionHandler(.failure(NCDataManagerError.invalidResponse))
				}
			case let .failure(error):
				completionHandler(.failure(error))
			}
		}, elseLoad: { completion in
			self.api.image(corporationID: corporationID, dimension: dimension * Int(UIScreen.main.scale)) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func image(allianceID: Int64, dimension: Int, completionHandler: @escaping (NCResult<UIImage>) -> Void) {
		loadFromCache(forKey: "image.alliance.\(allianceID).\(dimension)", account: nil, cachePolicy: cachePolicy, completionHandler: { (result: NCResult<Data>) in
			switch result {
			case let .success(value: value, cacheRecordID: recordID):
				if let image = UIImage(data: value, scale: UIScreen.main.scale) {
					completionHandler(.success(value: image, cacheRecordID: recordID))
				}
				else {
					completionHandler(.failure(NCDataManagerError.invalidResponse))
				}
			case let .failure(error):
				completionHandler(.failure(error))
			}
		}, elseLoad: { completion in
			self.api.image(allianceID: allianceID, dimension: dimension * Int(UIScreen.main.scale)) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func locations(ids: [Int64], completionHandler: @escaping ([Int64: NCLocation]) -> Void) {
		var locations = [Int64: NCLocation]()
		var missing = [Int64]()
		
		for id in ids {
			if (66000000 < id && id < 66014933) { //staStations
				if let station = NCDatabase.sharedDatabase?.staStations[Int(id) - 6000001] {
					locations[id] = NCLocation(station)
				}
				else {
					missing.append(id)
				}
			}
			else if (60000000 < id && id < 61000000) { //staStations
				if let station = NCDatabase.sharedDatabase?.staStations[Int(id)] {
					locations[id] = NCLocation(station)
				}
				else {
					missing.append(id)
				}
			}
			else if let int = Int(exactly: id) { //mapDenormalize
				
				if let mapDenormalize = NCDatabase.sharedDatabase?.mapDenormalize[int] {
					locations[id] = NCLocation(mapDenormalize)
				}
				else {
					missing.append(id)
				}
			}
			else {
				missing.append(id)
			}
		}
		if missing.count > 0 {
			api.universe.names(ids: missing) { result in
				switch result {
				case let .success(value):
					for name in value {
						if let location = NCLocation(name) {
							locations[name.id] = location
						}
					}
				case .failure:
					break
				}
				completionHandler(locations)
			}
		}
		else {
			DispatchQueue.main.async {
				completionHandler(locations)
			}
		}
	}
	
	func updateMarketPrices(completionHandler: ((_ isUpdated: Bool) -> Void)?) {
		NCCache.sharedCache?.performBackgroundTask{ managedObjectContext in
			let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: "ESMarketPrices", account: nil)))?.last
			if record == nil || record!.expired {
				self.marketPrices { result in
					let _ = self
					switch result {
					case let .success(value: value, cacheRecordID: _):
						NCCache.sharedCache?.performBackgroundTask{ managedObjectContext in
							if let objects = try? managedObjectContext.fetch(NSFetchRequest<NCCachePrice>(entityName: "Price")) {
								for object in objects {
									managedObjectContext.delete(object)
								}
							}
							for price in value {
								let record = NCCachePrice(entity: NSEntityDescription.entity(forEntityName: "Price", in: managedObjectContext)!, insertInto: managedObjectContext)
								record.typeID = Int32(price.typeID)
								record.price = price.averagePrice
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

	func marketHistory(typeID: Int, regionID: Int, completionHandler: @escaping (NCResult<[ESMarketHistory]>) -> Void) {
		loadFromCache(forKey: "ESMarketHistory.\(regionID).\(typeID)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.market.history(typeID: typeID, regionID: regionID) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	//MARK: Private
	
	func marketPrices(completionHandler: @escaping (NCResult<[ESMarketPrice]>) -> Void) {
		loadFromCache(forKey: "ESMarketPrices", account: nil, cachePolicy: .reloadIgnoringLocalCacheData, completionHandler: completionHandler, elseLoad: { completion in
			self.api.market.prices { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	
	private func loadFromCache<T> (forKey key: String,
	                           account: String?,
	                           cachePolicy:URLRequest.CachePolicy,
	                           completionHandler: @escaping (NCResult<T>) -> Void,
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
					cache.store(value as? NSSecureCoding, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { objectID in
						completionHandler(.success(value: value, cacheRecordID: objectID))
					}
				case let .failure(error):
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
						completionHandler(.success(value: object, cacheRecordID: record!.objectID))
					}
					else {
						progress.becomeCurrent(withPendingUnitCount: 1)
						loader { (result, cacheTime) in
							switch (result) {
							case let .success(value):
								cache.store(value as? NSSecureCoding, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { objectID in
									completionHandler(.success(value: value, cacheRecordID: objectID))
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
						completionHandler(.success(value: object, cacheRecordID: record!.objectID))
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
				let expired = record?.expired ?? true
				DispatchQueue.main.async {
					if let object = object {
						progress.completedUnitCount += 1
						completionHandler(.success(value: object, cacheRecordID: record!.objectID))
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
								cache.store(value as? NSSecureCoding, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { objectID in
									completionHandler(.success(value: value, cacheRecordID: objectID))
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
	
	/*
	func addAPI(keyID:Int, vCode:String, excludeCharacterIDs:IndexSet, completionHandler: @escaping (_ accounts:[NSManagedObjectID], _ error: Error?) -> Void) {
		let api = EVEOnlineAPI(apiKey: EVEAPIKey(keyID: keyID, vCode: vCode), cachePolicy: .reloadIgnoringLocalCacheData)
		api.apiKeyInfo { (result, error) in
			if let result = result, let storage = NCStorage.sharedStorage {
				storage.performBackgroundTask({ (managedObjectContext) in
					let request = NSFetchRequest<NCAPIKey>(entityName: "APIKey")
					request.predicate = NSPredicate(format: "keyID == %d", Int32(keyID))
					request.fetchLimit = 1
					
					var apiKey = (try? managedObjectContext.fetch(request))?.last
					if let key = apiKey, key.vCode == vCode {
						managedObjectContext.delete(key)
						apiKey = nil
					}
					
					if apiKey == nil {
						apiKey = NCAPIKey(entity: NSEntityDescription.entity(forEntityName: "APIKey", in: managedObjectContext)!, insertInto: managedObjectContext)
						apiKey!.keyID = Int32(keyID)
						apiKey!.vCode = vCode
						apiKey!.apiKeyInfo = result
					}
					
					var accounts = [NSManagedObjectID]()
					let ed = NSExpressionDescription()
					ed.name = "order"
					ed.expressionResultType = .integer32AttributeType
					ed.expression = NSExpression(format: "max(order)")
					
					let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "Account")
					fetchRequest.propertiesToFetch = [ed];
					fetchRequest.resultType = .dictionaryResultType;
					var order = (try? managedObjectContext.fetch(fetchRequest))?.last?["order"] as? Int ?? 0
					
					mainLoop: for character in result.key.characters {
						if excludeCharacterIDs.contains(character.characterID) {
							continue
						}
						if let accounts = apiKey?.accounts as? Set<NCAccount> {
							for account in accounts {
								if account.characterID == character.characterID {
									continue mainLoop
								}
							}
						}
						let account = NCAccount(entity: NSEntityDescription.entity(forEntityName: "Account", in: managedObjectContext)!, insertInto: managedObjectContext)
						account.apiKey = apiKey
						account.characterID = character.characterID
						account.order = Int32(order);
						account.uuid = UUID().uuidString
						accounts.append(account.objectID)
						order += 1
					}
					
					DispatchQueue.main.async {
						completionHandler(accounts, nil)
					}
				})
			}
			else {
				completionHandler([], error ?? NCDataManagerError.InternalError)
			}
		}
	}
	
	func apiKeyInfo(keyID:Int, vCode:String, completionHandler: @escaping (_ result: EVEAPIKeyInfo?, _ error: Error?) -> Void) {
		let api = EVEOnlineAPI(apiKey: EVEAPIKey(keyID: keyID, vCode: vCode), cachePolicy: .useProtocolCachePolicy)
		api.apiKeyInfo { (result, error) in
			if let result = result {
				completionHandler(result, nil)
			}
			else {
				completionHandler(nil, error ?? NCDataManagerError.InternalError)
			}
		}
	}

	func characterSheet(account: NCAccount, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: EVECharacterSheet?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
		loadFromCache(forKey: "EVECharacterSheet", account: account.uuid, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { (block) -> Void in
			let api = EVEOnlineAPI(apiKey: account.eveAPIKey, cachePolicy: cachePolicy)
			api.characterSheet(completionBlock: { (result, error) in
				if let result = result {
					block(result, nil, result.currentTime, result.cachedUntil)
				}
				else {
					block(nil, error ?? NCDataManagerError.InternalError, nil, nil)
				}
			})
		})
	}

	func skillQueue(account: NCAccount, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: EVESkillQueue?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
		loadFromCache(forKey: "EVESkillQueue", account: account.uuid, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { (block) -> Void in
			let api = EVEOnlineAPI(apiKey: account.eveAPIKey, cachePolicy: cachePolicy)
			api.skillQueue(completionBlock: { (result, error) in
				if let result = result {
					block(result, nil, result.currentTime, result.cachedUntil)
				}
				else {
					block(nil, error ?? NCDataManagerError.InternalError, nil, nil)
				}
			})
		})
	}

	func characterInfo(account: NCAccount, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: EVECharacterInfo?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
		loadFromCache(forKey: "EVECharacterInfo", account: account.uuid, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { (block) -> Void in
			let api = EVEOnlineAPI(apiKey: account.eveAPIKey, cachePolicy: cachePolicy)
			api.characterInfo(characterID: account.characterID, completionBlock: { (result, error) in
				if let result = result {
					block(result, nil, result.currentTime, result.cachedUntil)
				}
				else {
					block(nil, error ?? NCDataManagerError.InternalError, nil, nil)
				}
			})
		})
	}

	func accountStatus(account: NCAccount, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: EVEAccountStatus?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
		loadFromCache(forKey: "EVEAccountStatus", account: account.uuid, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { (block) -> Void in
			let api = EVEOnlineAPI(apiKey: account.eveAPIKey, cachePolicy: cachePolicy)
			api.accountStatus(completionBlock: { (result, error) in
				if let result = result {
					block(result, nil, result.currentTime, result.cachedUntil)
				}
				else {
					block(nil, error ?? NCDataManagerError.InternalError, nil, nil)
				}
			})
		})
	}

	func accountBalance(account: NCAccount, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: EVEAccountBalance?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
		loadFromCache(forKey: "EVEAccountBalance", account: account.uuid, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { (block) -> Void in
			let api = EVEOnlineAPI(apiKey: account.eveAPIKey, cachePolicy: cachePolicy)
			api.accountBalance(completionBlock: { (result, error) in
				if let result = result {
					block(result, nil, result.currentTime, result.cachedUntil)
				}
				else {
					block(nil, error ?? NCDataManagerError.InternalError, nil, nil)
				}
			})
		})
	}

	func image(characterID: Int64, preferredSize: CGSize, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: UIImage?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
	}

	func image(corporationID: Int64, preferredSize: CGSize, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: UIImage?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
	}

	func image(allianceID: Int64, preferredSize: CGSize, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: UIImage?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
	}

	func image(typeID: Int, preferredSize: CGSize, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: UIImage?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
	}

	func callList(cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: EVECallList?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
	}
	
	func price(typeIDs: [Int], completionHandler: @escaping (_ result: EVECallList?, _ error: Error?) -> Void) {
	}

	func marketPrices(cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: [ESMarketPrice]?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
		loadFromCache(forKey: "ESMarketPrices", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { (block) -> Void in
			let api = ESAPI()
			api.marketPrices(completionBlock: { (result, error) in
				if let result = result {
					block(result, nil, Date(), Date(timeIntervalSinceNow: 3600 * 24))
				}
				else {
					block(nil, error ?? NCDataManagerError.InternalError, nil, nil)
				}
			})
		})
	}
	
	func updateMarketPrices(completionHandler: ((_ result: [ESMarketPrice]?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void)?) {
		NCCache.sharedCache?.performBackgroundTask({ (managedObjectContext) in
			let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: "ESMarketPrices", account: nil)))?.last
			if record == nil || record!.expired {
				self.marketPrices(cachePolicy: .useProtocolCachePolicy, completionHandler: { (result, managedObjectID, error) in
					NCCache.sharedCache?.performBackgroundTask({ (managedObjectContext) in
						if let result = result {
							if let objects = try? managedObjectContext.fetch(NSFetchRequest<NCCachePrice>(entityName: "CachePrice")) {
								for object in objects {
									managedObjectContext.delete(object)
								}
							}
							for price in result {
								let record = NCCachePrice(entity: NSEntityDescription.entity(forEntityName: "CachePrice", in: managedObjectContext)!, insertInto: managedObjectContext)
								record.typeID = Int32(price.typeID)
								record.price = price.adjustedPrice
							}
						}
					})
				})
			}
		})
	}

	//MARK: Private
	
	private func loadFromCache<Element> (forKey key: String,
	                           account: String?,
	                           cachePolicy:URLRequest.CachePolicy,
	                           completionHandler: @escaping (_ result: Element?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void,
	                           elseLoad loader: @escaping (_ finish: @escaping(_ result: Element?, _ error: Error?, _ date: Date?, _ expireDate: Date?) -> Void) -> Void) {
		guard let cache = NCCache.sharedCache else {
			completionHandler(nil, nil, NCDataManagerError.InternalError)
			return
		}
		
		let progress = Progress(totalUnitCount: 1)
		
		switch cachePolicy {
		case .reloadIgnoringLocalCacheData:
			progress.becomeCurrent(withPendingUnitCount: 1)
			loader { (result, error, date, expireDate) in
				if let result = result as? NSSecureCoding {
					cache.store(result, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow:3), error: error, completionHandler: { (objectID) in
						completionHandler(nil, objectID, error)
					})
				}
				else {
					cache.store(nil, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow:3), error: error, completionHandler: { (objectID) in
						completionHandler(nil, objectID, error)
					})
				}
			}
			progress.resignCurrent()
		case .returnCacheDataElseLoad:
			cache.performBackgroundTask { (managedObjectContext) in
				let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)))?.last
				let object = record?.data?.data as? Element
				
				DispatchQueue.main.async {
					if let object = object {
						progress.completedUnitCount += 1
						completionHandler(object, record?.objectID, nil)
					}
					else {
						progress.becomeCurrent(withPendingUnitCount: 1)
						loader { (result, error, date, expireDate) in
							if let result = result as? NSSecureCoding {
								cache.store(result, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow:3), error: error, completionHandler: { (objectID) in
									completionHandler(nil, objectID, error)
								})
							}
							else {
								cache.store(nil, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow:3), error: error, completionHandler: { (objectID) in
									completionHandler(nil, objectID, error)
								})
							}
						}
						progress.resignCurrent()
					}
				}
			}
		case .returnCacheDataDontLoad:
			cache.performBackgroundTask { (managedObjectContext) in
				let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)))?.last
				let object = record?.data?.data as? Element
				
				DispatchQueue.main.async {
					if let object = object {
						progress.completedUnitCount += 1
						completionHandler(object, record?.objectID, nil)
					}
					else {
						completionHandler(nil, nil, NCDataManagerError.NoCacheData)
					}
				}
			}
		default:
			cache.performBackgroundTask { (managedObjectContext) in
				let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: key, account: account)))?.last
				let object = record?.data?.data as? Element
				let expired = record?.expired ?? true
				DispatchQueue.main.async {
					if let object = object {
						progress.completedUnitCount += 1
						completionHandler(object, record?.objectID, nil)
						if expired {
							loader { (result, error, date, expireDate) in
								if let result = result as? NSSecureCoding {
									cache.store(result, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow:3), error: error, completionHandler: nil)
								}
								else {
									cache.store(nil, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow:3), error: error, completionHandler: nil)
								}
							}
						}
					}
					else {
						progress.becomeCurrent(withPendingUnitCount: 1)
						loader { (result, error, date, expireDate) in
							if let result = result as? NSSecureCoding {
								cache.store(result, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow:3), error: error, completionHandler: { (objectID) in
									completionHandler(nil, objectID, error)
								})
							}
							else {
								cache.store(nil, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow:3), error: error, completionHandler: { (objectID) in
									completionHandler(nil, objectID, error)
								})
							}
						}
						progress.resignCurrent()
					}
				}
			}
			break
		}
	}
*/
//	- (void) locationWithLocationIDs:(NSArray<NSNumber*>*) locationIDs cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(NSDictionary<NSNumber*, NCLocation*>* result, NSError* error)) block;
}
