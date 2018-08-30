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

protocol APIResultProtocol {
	associatedtype Value
	var value: Value {get}
	var cachedUntil: Date? {get}
}

struct APIResult<Value>: APIResultProtocol {
	var value: Value
	var cachedUntil: Date?
	func map<T>(_ transform: (Value) throws -> T) rethrows -> APIResult<T> {
		return try APIResult<T>(value: transform(value), cachedUntil: cachedUntil)
	}
}


protocol CharacterAPI: class {
	func characterInformation() -> Future<APIResult<ESI.Character.Information>>
	func characterInformation(with characterID: Int64) -> Future<APIResult<ESI.Character.Information>>
	func blueprints() -> Future<APIResult<[ESI.Character.Blueprint]>>
	func character() -> Future<APIResult<Character>>
}

protocol SkillsAPI: class {
	func characterAttributes() -> Future<APIResult<ESI.Skills.CharacterAttributes>>
	func skillQueue() -> Future<APIResult<[ESI.Skills.SkillQueueItem]>>
	func skills() -> Future<APIResult<ESI.Skills.CharacterSkills>>
}

protocol ClonesAPI: class {
	func clones() -> Future<APIResult<ESI.Clones.JumpClones>>
	func implants() -> Future<APIResult<[Int]>>
}

protocol ImageAPI: class {
	func image(characterID: Int64, dimension: Int) -> Future<APIResult<UIImage>>
	func image(corporationID: Int64, dimension: Int) -> Future<APIResult<UIImage>>
	func image(allianceID: Int64, dimension: Int) -> Future<APIResult<UIImage>>
	func image(typeID: Int, dimension: Int) -> Future<APIResult<UIImage>>
}

protocol CorporationAPI: class {
	func corporationInformation(corporationID: Int64) -> Future<APIResult<ESI.Corporation.Information>>
	func divisions() -> Future<APIResult<ESI.Corporation.Divisions>>
}

protocol AllianceAPI: class {
	func allianceInformation(allianceID: Int64) -> Future<APIResult<ESI.Alliance.Information>>
}

protocol LocationAPI: class {
	func characterLocation() -> Future<APIResult<ESI.Location.CharacterLocation>>
	func characterShip() -> Future<APIResult<ESI.Location.CharacterShip>>
}

protocol StatusAPI: class {
	func serverStatus() -> Future<APIResult<ESI.Status.ServerStatus>>
}

protocol WalletAPI: class {
	func walletBalance() -> Future<APIResult<Double>>
	func walletJournal() -> Future<APIResult<[ESI.Wallet.WalletJournalItem]>>
	func walletTransactions() -> Future<APIResult<[ESI.Wallet.Transaction]>>
}

typealias API = CharacterAPI & SkillsAPI & ClonesAPI & ImageAPI & CorporationAPI & AllianceAPI & LocationAPI & StatusAPI & WalletAPI

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
	
	//MARK: CharacterAPI

	func characterInformation() -> Future<APIResult<ESI.Character.Information>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return characterInformation(with: id)
	}
	
	func characterInformation(with characterID: Int64) -> Future<APIResult<ESI.Character.Information>> {
		let esi = self.esi
		return load(for: "ESI.Character.Information.\(characterID)", account: account, loader: { etag in
			return esi.character.getCharactersPublicInformation(characterID: Int(characterID), ifNoneMatch: etag)
		})
	}

	func blueprints() -> Future<APIResult<[ESI.Character.Blueprint]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return load(for: "ESI.Character.Blueprint", account: account, loader: { etag in
			return esi.character.getBlueprints(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func character() -> Future<APIResult<Character>> {
		
		return self.sde.performBackgroundTask{ [weak self] context -> APIResult<Character> in
			guard let strongSelf = self else {throw NCError.cancelled(type: APIClient.self, function: #function)}
			let (attributes, skills, skillQueue, implants) = try all(strongSelf.characterAttributes(),
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
			let cachedUntil = [attributes.cachedUntil, skills.cachedUntil, skillQueue.cachedUntil, implants.cachedUntil].compactMap {$0}.min()
			return APIResult(value: character, cachedUntil: cachedUntil)
		}
	}
	
	//MARK: SkillsAPI

	func characterAttributes() -> Future<APIResult<ESI.Skills.CharacterAttributes>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return load(for: "ESI.Skills.CharacterAttributes", account: account, loader: { etag in
			return esi.skills.getCharacterAttributes(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func skillQueue() -> Future<APIResult<[ESI.Skills.SkillQueueItem]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return load(for: "ESI.Skills.SkillQueueItem", account: account, loader: { etag in
			return esi.skills.getCharactersSkillQueue(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func skills() -> Future<APIResult<ESI.Skills.CharacterSkills>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return load(for: "ESI.Skills.CharacterSkills", account: account, loader: { etag in
			return esi.skills.getCharacterSkills(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	//MARK: ClonesAPI

	func implants() -> Future<APIResult<[Int]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return load(for: "Implants", account: account, loader: { etag in
			return esi.clones.getActiveImplants(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func clones() -> Future<APIResult<ESI.Clones.JumpClones>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return load(for: "ESI.Clones.JumpClones", account: account, loader: { etag in
			return esi.clones.getClones(characterID: Int(id), ifNoneMatch: etag)
		})
	}

	//MARK: ImageAPI

	func image(characterID: Int64, dimension: Int) -> Future<APIResult<UIImage>> {
		let esi = self.esi
		return load(for: "image.character.\(characterID).\(dimension)", account: nil, loader: { (_) -> Future<ESI.Result<Data>> in
			return esi.image(characterID: Int(characterID), dimension: dimension * Int(UIScreen.main.scale))
		}).then { result -> APIResult<UIImage> in
			return try result.map { value -> UIImage in
				guard let image = UIImage(data: value) else {throw NCError.invalidImageFormat}
				return image
			}
		}
	}
	
	func image(corporationID: Int64, dimension: Int) -> Future<APIResult<UIImage>> {
		let esi = self.esi
		return load(for: "image.corporation.\(corporationID).\(dimension)", account: nil, loader: { (_) -> Future<ESI.Result<Data>> in
			return esi.image(corporationID: Int(corporationID), dimension: dimension * Int(UIScreen.main.scale))
		}).then { result -> APIResult<UIImage> in
			return try result.map { value -> UIImage in
				guard let image = UIImage(data: value) else {throw NCError.invalidImageFormat}
				return image
			}
		}
	}
	
	func image(allianceID: Int64, dimension: Int) -> Future<APIResult<UIImage>> {
		let esi = self.esi
		return load(for: "image.alliance.\(allianceID).\(dimension)", account: nil, loader: { (_) -> Future<ESI.Result<Data>> in
			return esi.image(allianceID: Int(allianceID), dimension: dimension * Int(UIScreen.main.scale))
		}).then { result -> APIResult<UIImage> in
			return try result.map { value -> UIImage in
				guard let image = UIImage(data: value) else {throw NCError.invalidImageFormat}
				return image
			}
		}
	}
	
	func image(typeID: Int, dimension: Int) -> Future<APIResult<UIImage>> {
		let esi = self.esi
		return load(for: "image.type.\(typeID).\(dimension)", account: nil, loader: { (_) -> Future<ESI.Result<Data>> in
			return esi.image(typeID: typeID, dimension: dimension * Int(UIScreen.main.scale))
		}).then { result -> APIResult<UIImage> in
			return try result.map { value -> UIImage in
				guard let image = UIImage(data: value) else {throw NCError.invalidImageFormat}
				return image
			}
		}
	}

	//MARK: CorporationAPI

	func corporationInformation(corporationID: Int64) -> Future<APIResult<ESI.Corporation.Information>> {
		let esi = self.esi
		return load(for: "ESI.Corporation.Information.\(corporationID)", account: account, loader: { etag in
			return esi.corporation.getCorporationInformation(corporationID: Int(corporationID), ifNoneMatch: etag)
		})
	}
	
	func divisions() -> Future<APIResult<ESI.Corporation.Divisions>> {
		let esi = self.esi
		return load(for: "ESI.Corporation.Division", account: account, loader: { etag in
			return self.characterInformation().then { result in
				return esi.corporation.getCorporationDivisions(corporationID: result.value.corporationID, ifNoneMatch: etag)
			}
		})
	}
	
	//MARK: AllianceAPI
	
	func allianceInformation(allianceID: Int64) -> Future<APIResult<ESI.Alliance.Information>> {
		let esi = self.esi
		return load(for: "ESI.Alliance.Information.\(allianceID)", account: account, loader: { etag in
			return esi.alliance.getAllianceInformation(allianceID: Int(allianceID), ifNoneMatch: etag)
		})
	}
	
	//MARK: LocationAPI
	
	func characterLocation() -> Future<APIResult<ESI.Location.CharacterLocation>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return load(for: "ESI.Location.CharacterLocation", account: account, loader: { etag in
			return esi.location.getCharacterLocation(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func characterShip() -> Future<APIResult<ESI.Location.CharacterShip>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return load(for: "ESI.Location.CharacterShip", account: account, loader: { etag in
			return esi.location.getCurrentShip(characterID: Int(id), ifNoneMatch: etag)
		})
	}

	//MARK: StatusAPI

	func serverStatus() -> Future<APIResult<ESI.Status.ServerStatus>> {
		let esi = self.esi
		return load(for: "ESI.Status.ServerStatus", account: account, loader: { etag in
			return esi.status.retrieveTheUptimeAndPlayerCounts(ifNoneMatch: etag)
		})
	}
	
	//MARK: WalletAPI
	
	func walletBalance() -> Future<APIResult<Double>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return load(for: "ESI.WalletBalance", account: account, loader: { etag in
			return esi.wallet.getCharactersWalletBalance(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func walletJournal() -> Future<APIResult<[ESI.Wallet.WalletJournalItem]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return load(for: "ESI.Wallet.WalletJournalItem", account: account, loader: { etag in
			return esi.wallet.getCharacterWalletJournal(characterID: Int(id), ifNoneMatch: etag)
		})
	}
	
	func walletTransactions() -> Future<APIResult<[ESI.Wallet.Transaction]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return load(for: "ESI.Wallet.Transaction", account: account, loader: { etag in
			return esi.wallet.getWalletTransactions(characterID: Int(id), ifNoneMatch: etag)
		})
	}

}

extension APIClient {
	func load<T: Codable>(for identifier: String, account: String?, loader: @escaping (_ etag: String?) -> Future<ESI.Result<T>>) -> Future<APIResult<T>> {
		let cachePolicy = self.cachePolicy
		let cache = self.cache
		return cache.performBackgroundTask { (context) -> APIResult<T> in
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
			
			func makeResult() throws -> APIResult<T>{
				try? context.save()
				
				guard let cacheRecord = cacheRecord,
					let value: T = cacheRecord.getValue() else {throw NCError.noCachedResult(type: T.self, identifier: identifier)}
				return APIResult(value: value, cachedUntil: cacheRecord.cachedUntil)
//				return APIResult<T>(value: value, cachedUntil: cacheRecord.cachedUntil, observer: APICacheRecordObserver<APIResult<T>>(cacheRecord: cacheRecord, cache: cache))
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
