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


class NCDataManager {
	enum NCDataManagerError: Error {
		case InternalError
		case NoCacheData
	}

	
	init() {}
	
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
						apiKey = NCAPIKey(context: managedObjectContext)
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
								if account.characterID == Int32(character.characterID) {
									continue mainLoop
								}
							}
						}
						let account = NCAccount(context: managedObjectContext)
						account.apiKey = apiKey
						account.characterID = Int32(character.characterID)
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
			api.characterInfo(characterID: Int(account.characterID), completionBlock: { (result, error) in
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

	func image(characterID: Int, preferredSize: CGSize, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: UIImage?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
	}

	func image(corporationID: Int, preferredSize: CGSize, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: UIImage?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
	}

	func image(allianceID: Int, preferredSize: CGSize, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: UIImage?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
	}

	func image(typeID: Int, preferredSize: CGSize, cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: UIImage?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
	}

	func callList(cachePolicy:URLRequest.CachePolicy, completionHandler: @escaping (_ result: EVECallList?, _ cacheRecordID: NSManagedObjectID?, _ error: Error?) -> Void) {
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

//	- (void) locationWithLocationIDs:(NSArray<NSNumber*>*) locationIDs cachePolicy:(NSURLRequestCachePolicy) cachePolicy completionHandler:(void(^)(NSDictionary<NSNumber*, NCLocation*>* result, NSError* error)) block;
}
