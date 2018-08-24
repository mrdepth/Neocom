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
import Alamofire
import Expressible

protocol CharacterAPI {
	func characterInformation() -> Future<CachedValue<ESI.Character.Information>>
	func characterInformation(with characterID: Int64?) -> Future<CachedValue<ESI.Character.Information>>
	func blueprints() -> Future<CachedValue<[ESI.Character.Blueprint]>>
	func character() -> Future<CachedValue<Character>>
}

protocol SkillsAPI {
	func characterAttributes() -> Future<CachedValue<ESI.Skills.CharacterAttributes>>
	func skillQueue() -> Future<CachedValue<[ESI.Skills.SkillQueueItem]>>
	func skills() -> Future<CachedValue<ESI.Skills.CharacterSkills>>
}

protocol ClonesAPI {
	func clones() -> Future<CachedValue<ESI.Clones.JumpClones>>
	func implants() -> Future<CachedValue<[Int]>>
}

typealias API = CharacterAPI & SkillsAPI & ClonesAPI

class APIClient {
	
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
}

extension APIClient: CharacterAPI {
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

	func blueprints() -> Future<CachedValue<[ESI.Character.Blueprint]>> {
		guard let id = characterID else {
			return .init(.failure(NCError.missingCharacterID(function: #function)))
		}
		
		let esi = self.esi
		return load(for: "ESI.Character.Blueprint", account: account, loader: { etag in
			return esi.character.getBlueprints(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func character() -> Future<CachedValue<Character>> {
		
		return self.sde.performBackgroundTask{ [weak self] context -> CachedValue<Character> in
			guard let strongSelf = self else {throw NCError.cancelled(type: APIClient.self, function: #function)}
			let values = try all(strongSelf.characterAttributes(),
								 strongSelf.skills(),
								 strongSelf.skillQueue(),
								 strongSelf.implants()).get()
			let result = all(values).map { (attributes, skills, skillQueue, implants) -> Character in
				let characterAttributes = Character.Attributes(intelligence: attributes.intelligence,
															   memory: attributes.memory,
															   perception: attributes.perception,
															   willpower: attributes.willpower,
															   charisma: attributes.charisma)
				
				var augmentations = Character.Attributes.none
				
				for implant in implants {
					guard let type = context.invType(implant) else {continue}
					let attributes = [SDEAttributeID.intelligence, SDEAttributeID.memory, SDEAttributeID.perception, SDEAttributeID.willpower, SDEAttributeID.charisma].lazy.map({($0, Int(type[$0]?.value ?? 0))})
					guard let value = attributes.first(where: {$0.1 > 0}) else {continue}
					augmentations[value.0] += value.1
				}
				
				var trainedSkills = Dictionary(skills.skills.map { ($0.skillID, $0.trainedSkillLevel)}, uniquingKeysWith: max)
				
				let currentDate = Date()
				var validSkillQueue = skillQueue.filter{$0.finishDate != nil}
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
				return character
			}
			return result
		}
	}
}

extension APIClient: SkillsAPI {

	func characterAttributes() -> Future<CachedValue<ESI.Skills.CharacterAttributes>> {
		guard let id = characterID else {
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
	
}

extension APIClient: ClonesAPI {
	
	func implants() -> Future<CachedValue<[Int]>> {
		guard let id = characterID else {
			return .init(.failure(NCError.missingCharacterID(function: #function)))
		}
		
		let esi = self.esi
		return load(for: "Implants", account: account, loader: { etag in
			return esi.clones.getActiveImplants(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func clones() -> Future<CachedValue<ESI.Clones.JumpClones>> {
		guard let id = characterID else {
			return .init(.failure(NCError.missingCharacterID(function: #function)))
		}
		
		let esi = self.esi
		return load(for: "ESI.Clones.JumpClones", account: account, loader: { etag in
			return esi.clones.getClones(characterID: Int(id), ifNoneMatch: etag)
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
				return CachedValue<T>(value: value, cachedUntil: cacheRecord.cachedUntil, observer: APICacheRecordObserver<T>(cacheRecord: cacheRecord, cache: cache))
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
