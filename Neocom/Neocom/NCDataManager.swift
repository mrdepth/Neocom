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
	case success(value: T, cacheRecordID: NSManagedObjectID)
	case failure(Error)
}

enum NCResult<T> {
	case success(T)
	case failure(Error)
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
	lazy var api: ESAPI = {
		if let token = self.token {
			return ESAPI(token: token, clientID: ESClientID, secretKey: ESSecretKey, cachePolicy: self.cachePolicy)
		}
		else {
			return ESAPI(cachePolicy: self.cachePolicy)
		}
	}()
	
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
	
	func character(completionHandler: @escaping (NCCachedResult<ESCharacter>) -> Void) {
		loadFromCache(forKey: "ESCharacter", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func corporation(corporationID: Int64, completionHandler: @escaping (NCCachedResult<ESCorporation>) -> Void) {
		loadFromCache(forKey: "ESCoproration.\(corporationID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.corporation(corporationID: corporationID) { result in
				completion(result, 3600.0)
			}
		})
	}

	func alliance(allianceID: Int64, completionHandler: @escaping (NCCachedResult<ESAlliance>) -> Void) {
		loadFromCache(forKey: "ESAlliance.\(allianceID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.alliance(allianceID: allianceID) { result in
				completion(result, 3600.0)
			}
		})
	}

	func skillQueue(completionHandler: @escaping (NCCachedResult<[ESSkillQueueItem]>) -> Void) {
		loadFromCache(forKey: "ESSkillQueue", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character.skillQueue { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func skills(completionHandler: @escaping (NCCachedResult<ESSkills>) -> Void) {
		loadFromCache(forKey: "ESSkills", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character.skills { result in
				completion(result, 3600.0)
			}
		})
	}
	
	
	func wallets(completionHandler: @escaping (NCCachedResult<[ESWallet]>) -> Void) {
		loadFromCache(forKey: "ESWallets", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character.wallets { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func characterLocation(completionHandler: @escaping (NCCachedResult<ESCharacterLocation>) -> Void) {
		loadFromCache(forKey: "ESCharacterLocation", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character.location { result in
				completion(result, 3600.0)
			}
		})
	}

	func characterShip(completionHandler: @escaping (NCCachedResult<ESCharacterShip>) -> Void) {
		loadFromCache(forKey: "ESShip", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character.ship { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func clones(completionHandler: @escaping (NCCachedResult<ESClones>) -> Void) {
		loadFromCache(forKey: "ESClones", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.clones { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func image(characterID: Int64, dimension: Int, completionHandler: @escaping (NCCachedResult<UIImage>) -> Void) {
		loadFromCache(forKey: "image.character.\(characterID).\(dimension)", account: nil, cachePolicy: cachePolicy, completionHandler: { (result: NCCachedResult<Data>) in
			switch result {
			case let .success(value, recordID):
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
				completion(result, 3600.0 * 12)
			}
		})
	}
	
	func image(corporationID: Int64, dimension: Int, completionHandler: @escaping (NCCachedResult<UIImage>) -> Void) {
		loadFromCache(forKey: "image.corporation.\(corporationID).\(dimension)", account: nil, cachePolicy: cachePolicy, completionHandler: { (result: NCCachedResult<Data>) in
			switch result {
			case let .success(value, recordID):
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
				completion(result, 3600.0 * 12)
			}
		})
	}
	
	func image(allianceID: Int64, dimension: Int, completionHandler: @escaping (NCCachedResult<UIImage>) -> Void) {
		loadFromCache(forKey: "image.alliance.\(allianceID).\(dimension)", account: nil, cachePolicy: cachePolicy, completionHandler: { (result: NCCachedResult<Data>) in
			switch result {
			case let .success(value, recordID):
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
				completion(result, 3600.0 * 12)
			}
		})
	}

	func image(typeID: Int, dimension: Int, completionHandler: @escaping (NCCachedResult<UIImage>) -> Void) {
		loadFromCache(forKey: "image.type.\(typeID).\(dimension)", account: nil, cachePolicy: cachePolicy, completionHandler: { (result: NCCachedResult<Data>) in
			switch result {
			case let .success(value, recordID):
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
			self.api.image(typeID: typeID, dimension: dimension * Int(UIScreen.main.scale)) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	func locations(ids: [Int64], completionHandler: @escaping ([Int64: NCLocation]) -> Void) {
		var locations = [Int64: NCLocation]()
		var missing = [Int64]()
		var structures = [Int64]()
		
		for id in ids {
			if id > Int64(Int32.max) {
				structures.append(id)
			}
			else if (66000000 < id && id < 66014933) { //staStations
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
		let dispatchGroup = DispatchGroup()
		if missing.count > 0 {
			dispatchGroup.enter()
			self.universeNames(ids: missing) { result in
				let _ = self
				switch result {
				case let .success(value, _):
					for name in value {
						if let location = NCLocation(name) {
							locations[name.id] = location
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
	
	func universeNames(ids: [Int64], completionHandler: @escaping (NCCachedResult<[ESName]>) -> Void) {
		loadFromCache(forKey: "ESNames.\(ids.hashValue)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.universe.names(ids: ids) { result in
				completion(result, 3600.0 * 24)
			}
		})
	}

	func universeStructure(structureID: Int64, completionHandler: @escaping (NCCachedResult<ESStructure>) -> Void) {
		loadFromCache(forKey: "ESStructure.\(structureID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.universe.structure(structureID: structureID) { result in
				completion(result, 3600.0 * 24)
			}
		})
	}

	
	func updateMarketPrices(completionHandler: ((_ isUpdated: Bool) -> Void)?) {
		NCCache.sharedCache?.performBackgroundTask{ managedObjectContext in
			let record = (try? managedObjectContext.fetch(NCCacheRecord.fetchRequest(forKey: "ESMarketPrices", account: nil)))?.last
			if record == nil || record!.expired {
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

	func marketHistory(typeID: Int, regionID: Int, completionHandler: @escaping (NCCachedResult<[ESMarketHistory]>) -> Void) {
		loadFromCache(forKey: "ESMarketHistory.\(regionID).\(typeID)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.market.history(typeID: typeID, regionID: regionID) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	func marketOrders(typeID: Int, regionID: Int, completionHandler: @escaping (NCCachedResult<[ESMarketOrder]>) -> Void) {
		loadFromCache(forKey: "ESMarketOrder.\(regionID).\(typeID)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.market.orders(typeID: typeID, regionID: regionID) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	//MARK: Private
	
	func marketPrices(completionHandler: @escaping (NCCachedResult<[ESMarketPrice]>) -> Void) {
		loadFromCache(forKey: "ESMarketPrices", account: nil, cachePolicy: .reloadIgnoringLocalCacheData, completionHandler: completionHandler, elseLoad: { completion in
			self.api.market.prices { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	
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
					cache.store(value as? NSSecureCoding, forKey: key, account: account, date: Date(), expireDate: Date(timeIntervalSinceNow: cacheTime), error: nil) { objectID in
						completionHandler(.success(value: value, cacheRecordID: objectID))
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
	
}
