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
	lazy var api: ESI = {
		if let token = self.token {
			return ESI(token: token, clientID: ESClientID, secretKey: ESSecretKey, server: .tranquility, cachePolicy: self.cachePolicy)
		}
		else {
			return ESI(cachePolicy: self.cachePolicy)
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
	
	func character(characterID: Int64? = nil, completionHandler: @escaping (NCCachedResult<ESI.Character.Information>) -> Void) {
		let id = Int(characterID ?? self.characterID)
		loadFromCache(forKey: "ESI.Character.Information.\(id)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.character.getCharactersPublicInformation(characterID: id) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func corporation(corporationID: Int64, completionHandler: @escaping (NCCachedResult<ESI.Corporation.Information>) -> Void) {
		loadFromCache(forKey: "ESI.Corporation.Information.\(corporationID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.corporation.getCorporationInformation(corporationID: Int(corporationID)) { result in
				completion(result, 3600.0)
			}
		})
	}

	func alliance(allianceID: Int64, completionHandler: @escaping (NCCachedResult<ESI.Alliance.Information>) -> Void) {
		loadFromCache(forKey: "ESI.Alliance.Information.\(allianceID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.alliance.getAllianceInformation(allianceID: Int(allianceID)) { result in
				completion(result, 3600.0)
			}
		})
	}

	func skillQueue(completionHandler: @escaping (NCCachedResult<[ESI.Skills.SkillQueueItem]>) -> Void) {
		loadFromCache(forKey: "ESI.Skills.SkillQueueItem", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.skills.getCharactersSkillQueue(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func skills(completionHandler: @escaping (NCCachedResult<ESI.Skills.CharacterSkills>) -> Void) {
		loadFromCache(forKey: "ESI.Skills.CharacterSkills", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.skills.getCharacterSkills(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	
	func wallets(completionHandler: @escaping (NCCachedResult<[ESI.Wallet.Balance]>) -> Void) {
		loadFromCache(forKey: "ESI.Wallet.Balance", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.wallet.listWalletsAndBalances(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func characterLocation(completionHandler: @escaping (NCCachedResult<ESI.Location.CharacterLocation>) -> Void) {
		loadFromCache(forKey: "ESI.Location.CharacterLocation", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.location.getCharacterLocation(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}

	func characterShip(completionHandler: @escaping (NCCachedResult<ESI.Location.CharacterShip>) -> Void) {
		loadFromCache(forKey: "ESI.Location.CharacterShip", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.location.getCurrentShip(characterID: Int(self.characterID)) { result in
				completion(result, 3600.0)
			}
		})
	}
	
	func clones(completionHandler: @escaping (NCCachedResult<ESI.Clones.JumpClones>) -> Void) {
		loadFromCache(forKey: "ESI.Clones.JumpClones", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.clones.getClones(characterID: Int(self.characterID)) { result in
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
			self.api.image(characterID: Int(characterID), dimension: dimension * Int(UIScreen.main.scale)) { result in
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
			self.api.image(corporationID: Int(corporationID), dimension: dimension * Int(UIScreen.main.scale)) { result in
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
			self.api.image(allianceID: Int(allianceID), dimension: dimension * Int(UIScreen.main.scale)) { result in
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
	
	func universeNames(ids: [Int64], completionHandler: @escaping (NCCachedResult<[ESI.Universe.Name]>) -> Void) {
		let ids = ids.map{Int($0)}.sorted()
		loadFromCache(forKey: "ESI.Universe.Name.\(ids.hashValue)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.universe.getNamesAndCategoriesForSetOfIDs(ids: ids) { result in
				completion(result, 3600.0 * 24)
			}
		})
	}

	func universeStructure(structureID: Int64, completionHandler: @escaping (NCCachedResult<ESI.Universe.StructureInformation>) -> Void) {
		loadFromCache(forKey: "ESI.Universe.StructureInformation.\(structureID)", account: account, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.universe.getStructureInformation(structureID: structureID) { result in
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
			self.api.market.listHistoricalMarketStatisticsInRegion(regionID: regionID, typeID: typeID) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	func marketOrders(typeID: Int, regionID: Int, completionHandler: @escaping (NCCachedResult<[ESI.Market.Order]>) -> Void) {
		loadFromCache(forKey: "ESI.Market.Order.\(regionID).\(typeID)", account: nil, cachePolicy: cachePolicy, completionHandler: completionHandler, elseLoad: { completion in
			self.api.market.listOrdersInRegion(orderType: .all, regionID: regionID, typeID: typeID) { result in
				completion(result, 3600.0 * 12)
			}
		})
	}

	//MARK: Private
	
	func marketPrices(completionHandler: @escaping (NCCachedResult<[ESI.Market.Price]>) -> Void) {
		loadFromCache(forKey: "ESI.Market.Price", account: nil, cachePolicy: .reloadIgnoringLocalCacheData, completionHandler: completionHandler, elseLoad: { completion in
			self.api.market.listMarketPrices { result in
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
				let expired = record?.expired ?? true
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
