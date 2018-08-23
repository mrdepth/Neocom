//
//  API.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import EVEAPI
import CoreData
import Alamofire
import Expressible
import CloudData


protocol API {
	func characterInformation() -> Future<CachedValue<ESI.Character.Information>>
	func characterInformation(with characterID: Int64?) -> Future<CachedValue<ESI.Character.Information>>
	func characterAttributes() -> Future<CachedValue<ESI.Skills.CharacterAttributes>>
	func skillQueue() -> Future<CachedValue<[ESI.Skills.SkillQueueItem]>>
	func skills() -> Future<CachedValue<ESI.Skills.CharacterSkills>>
	func implants() -> Future<CachedValue<[Int]>>
//	func clones() -> Future<CachedValue<ESI.Clones.JumpClones>>
	func character() -> Future<CachedValue<Character>>
}

class APIObserver<Value: Codable> {
	var recordID: NSManagedObjectID?
	var dataID: NSManagedObjectID?
	var cache: Cache
	
	var handler: ((_ newValue: Value, _ cachedUntil: Date?) -> Void)? {
		didSet {
			if observer == nil {
				observer = NotificationCenter.default.addNotificationObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: nil, using: { [weak self] note in
					self?.didSave(note)
				})
			}
		}
	}
	
	private var observer: NotificationObserver?
	
	init(cache: Cache) {
		self.cache = cache
	}
	
	init(cacheRecord: CacheRecord, cache: Cache) {
		self.cache = cache
		recordID = cacheRecord.objectID
		dataID = cacheRecord.data?.objectID
	}
	
	private func didSave(_ note: Notification) {
		guard let objectIDs = (note.userInfo?[NSUpdatedObjectsKey] as? NSSet)?.compactMap ({ ($0 as? NSManagedObject)?.objectID ?? $0 as? NSManagedObjectID }) else {return}
		guard !Set(objectIDs).intersection([recordID, dataID].compactMap{$0}).isEmpty else {return}
		cache.performBackgroundTask { context -> Void in
			guard let recordID = self.recordID else {return}
			guard let record: CacheRecord = (try? context.existingObject(with: recordID)) ?? nil else {return}
			guard let value: Value = record.getValue() else {return}
			self.handler?(value, record.cachedUntil)
		}
	}
	
	func map<T: Codable>(_ transform: @escaping (Value) -> T ) -> APIObserver<T> {
		return APIObserverMap<T, Value>(self, transform: transform)
	}
}

class APIObserverMap<Value: Codable, Base: Codable>: APIObserver<Value> {
	var base: APIObserver<Base>
	var transform: (Base) -> Value
	
	override var handler: ((_ newValue: Value, _ cachedUntil: Date?) -> Void)? {
		didSet {
			let block = handler
			base.handler = { [weak self] (value, cachedUntil) in
				guard let transform = self?.transform else {return}
				block?(transform(value), cachedUntil)
			}
		}
	}
	
	init(_ base: APIObserver<Base>, transform: @escaping (Base) -> Value ) {
		self.base = base
		self.transform = transform
		super.init(cache: base.cache)
	}
}

enum Response<T> {
	case success(T)
	case failure(Error)
}

struct CachedValue<Value: Codable> {
	var value: Value
	var cachedUntil: Date?
	var observer: APIObserver<Value>
	
	func map<T: Codable>(_ transform: @escaping (Value) -> T ) -> CachedValue<T> {
		return CachedValue<T>(value: transform(value), cachedUntil: cachedUntil, observer: observer.map(transform))
	}
}


class APIClient: API {
	
	var cache: Cache
	var sde: SDE
	var cachePolicy: URLRequest.CachePolicy
	var server: ESI.Server
	private var account: String?
	private var oAuth2Token: OAuth2Token?
	private var characterID: Int64?
	
	private lazy var esi: ESI = ESI(token: self.oAuth2Token, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey, server: self.server, cachePolicy: self.cachePolicy)
	
	init(account: Account? = nil, server: ESI.Server = .tranquility, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, cache: Cache = CacheContainer.shared, sde: SDE = SDEContainer.shared) {
		self.account = account?.uuid
		self.cache = cache
		self.sde = sde
		self.cachePolicy = cachePolicy
		self.server = server
		self.oAuth2Token = account?.oAuth2Token
		self.characterID = account?.characterID
	}
	
	func characterInformation() -> Future<CachedValue<ESI.Character.Information>> {
		return characterInformation(with: nil)
	}
	
	func characterInformation(with characterID: Int64?) -> Future<CachedValue<ESI.Character.Information>> {
		guard let id = characterID ?? self.characterID else {
			return .init(.failure(NCError.missingCharacterID(function: #function)))
		}
		
		let esi = self.esi
		return load(for: "ESI.Character.Information.\(id)", account: account, loader: { etag in
			return esi.character.getCharactersPublicInformation(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func characterAttributes() -> Future<CachedValue<ESI.Skills.CharacterAttributes>> {
		guard let id = characterID ?? self.characterID else {
			return .init(.failure(NCError.missingCharacterID(function: #function)))
		}
		
		let esi = self.esi
		return load(for: "ESI.Skills.CharacterAttributes", account: account, loader: { etag in
			return esi.skills.getCharacterAttributes(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func skillQueue() -> Future<CachedValue<[ESI.Skills.SkillQueueItem]>> {
		guard let id = characterID else {
			return .init(.failure(NCError.missingCharacterID(function: #function)))
		}
		
		let esi = self.esi
		return load(for: "ESI.Skills.SkillQueueItem", account: account, loader: { etag in
			return esi.skills.getCharactersSkillQueue(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func skills() -> Future<CachedValue<ESI.Skills.CharacterSkills>> {
		guard let id = characterID else {
			return .init(.failure(NCError.missingCharacterID(function: #function)))
		}
		
		let esi = self.esi
		return load(for: "ESI.Skills.CharacterSkills", account: account, loader: { etag in
			return esi.skills.getCharacterSkills(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func implants() -> Future<CachedValue<[Int]>> {
		guard let id = characterID else {
			return .init(.failure(NCError.missingCharacterID(function: #function)))
		}
		
		let esi = self.esi
		return load(for: "Implants", account: account, loader: { etag in
			return esi.clones.getActiveImplants(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func character() -> Future<CachedValue<Character>> {

		let sde = self.sde
		return load(for: "Character", account: account, loader: { _ in
			return sde.performBackgroundTask{ [weak self] context -> ESI.Result<Character> in
				guard let strongSelf = self else {throw NCError.cancelled(type: APIClient.self, function: #function)}
				let (attributes, skills, skillQueue, implants) =
					try all(strongSelf.characterAttributes(),
							strongSelf.skills(),
							strongSelf.skillQueue(),
							strongSelf.implants()).get()
				
				let characterAttributes = Character.Attributes(intelligence: attributes.value.intelligence,
															   memory: attributes.value.memory,
															   perception: attributes.value.perception,
															   willpower: attributes.value.willpower,
															   charisma: attributes.value.charisma)
				
				var augmentations = Character.Attributes.none
				
				for implant in implants.value {
					guard let type = context.invType(implant) else {continue}
					let attributes = [SDEAttributeID.intelligence, SDEAttributeID.memory, SDEAttributeID.perception, SDEAttributeID.willpower, SDEAttributeID.charisma].lazy.map({($0, Int(type[$0]?.value ?? 0))})
					guard let value = attributes.first(where: {$0.1 > 0}) else {continue}
					augmentations[value.0] += value.1
				}

				var trainedSkills = Dictionary(skills.value.skills.map { ($0.skillID, $0.trainedSkillLevel)}, uniquingKeysWith: max)
				
				let currentDate = Date()
				var validSkillQueue = skillQueue.value.filter{$0.finishDate != nil}
				let i = validSkillQueue.partition(by: {$0.finishDate! > currentDate})
				for skill in validSkillQueue[..<i] {
					trainedSkills[skill.skillID] = max(trainedSkills[skill.skillID] ?? 0, skill.finishedLevel)
				}
				
				let sq = validSkillQueue[i...].sorted{$0.queuePosition < $1.queuePosition}.compactMap { i -> Character.SkillQueueItem? in
					guard let type = context.invType(i.skillID), let skill = Character.Skill(type: type) else {return nil}
					return Character.SkillQueueItem(skill: skill, queuedSkill: i)
				}
				
				let character = Character(attributes: characterAttributes,
										  augmentations: augmentations,
										  trainedSkills: trainedSkills,
										  skillQueue: sq)

				return ESI.Result(value: character, cached: 3600, etag: nil)
			}
		})
	}
}


extension APIClient {
	private func load<T: Codable>(for identifier: String, account: String?, loader: @escaping (_ etag: String?) -> Future<ESI.Result<T>>) -> Future<CachedValue<T>> {
		let cachePolicy = self.cachePolicy
		let cache = self.cache
		return cache.performBackgroundTask { (context) -> CachedValue<T> in
			var cacheRecord = context.record(identifier: identifier, account: account)
			
			func load(etag: String?) throws {
				let result = try loader(etag).get()
				if cacheRecord == nil {
					cacheRecord = context.newRecord(identifier: identifier, account: account)
				}
				cacheRecord?.setValue(result.value)
				cacheRecord?.date = Date()
				cacheRecord?.cachedUntil = result.cached.map{Date(timeIntervalSinceNow: $0)}
				cacheRecord?.etag = result.etag
			}
			
			func makeResult() throws -> CachedValue<T>{
				try? context.save()
				
				guard let cacheRecord = cacheRecord,
					let value: T = cacheRecord.getValue() else {throw NCError.noCachedResult(type: T.self, identifier: identifier)}
				return CachedValue<T>(value: value, cachedUntil: cacheRecord.cachedUntil, observer: APIObserver<T>(cacheRecord: cacheRecord, cache: cache))
			}
			
			
			switch cachePolicy {
			case .useProtocolCachePolicy, .reloadRevalidatingCacheData:
				if cacheRecord?.isExpired != false {
					do {
						try load(etag: cacheRecord?.etag)
					}
					catch {
						if case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 304)) = error {
							return try makeResult()
						}
						else if let cachedUntil = cacheRecord?.cachedUntil, Date().timeIntervalSince(cachedUntil) < Config.current.maxCacheTime {
							return try makeResult()
						}
						else {
							throw error
						}
					}
				}
				return try makeResult()
			case .reloadIgnoringLocalCacheData, .reloadIgnoringLocalAndRemoteCacheData:
				try load(etag: nil)
				return try makeResult()
			case .returnCacheDataElseLoad:
				do {
					return try makeResult()
				} catch { }
				try load(etag: cacheRecord?.etag)
				return try makeResult()
			case .returnCacheDataDontLoad:
				return try makeResult()
			}
		}
	}
}
