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

protocol ESIResultProtocol {
	associatedtype Value
	var value: Value {get}
	var expires: Date? {get}
}

extension ESI.Result: ESIResultProtocol {
	func map<T>(_ transform: (Value) throws -> T) rethrows -> ESI.Result<T> {
		return try ESI.Result<T>(value: transform(value), expires: expires)
	}
}

protocol CharacterAPI: class {
	func characterInformation(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Character.Information>>
	func characterInformation(with characterID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Character.Information>>
	func blueprints(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Character.Blueprint]>>
	func character(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<Character>>
}

protocol SkillsAPI: class {
	func characterAttributes(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Skills.CharacterAttributes>>
	func skillQueue(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Skills.SkillQueueItem]>>
	func skills(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Skills.CharacterSkills>>
}

protocol ClonesAPI: class {
	func clones(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Clones.JumpClones>>
	func implants(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[Int]>>
}

protocol ImageAPI: class {
	func image(characterID: Int64, dimension: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<UIImage>>
	func image(corporationID: Int64, dimension: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<UIImage>>
	func image(allianceID: Int64, dimension: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<UIImage>>
	func image(typeID: Int, dimension: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<UIImage>>
}

protocol CorporationAPI: class {
	func corporationInformation(corporationID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Corporation.Information>>
	func divisions(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Corporation.Divisions>>
}

protocol AllianceAPI: class {
	func allianceInformation(allianceID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Alliance.Information>>
}

protocol LocationAPI: class {
	func characterLocation(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Location.CharacterLocation>>
	func characterShip(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Location.CharacterShip>>
}

protocol StatusAPI: class {
	func serverStatus(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Status.ServerStatus>>
}

protocol WalletAPI: class {
	func walletBalance(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<Double>>
	func walletJournal(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Wallet.WalletJournalItem]>>
	func walletTransactions(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Wallet.Transaction]>>
}

typealias API = CharacterAPI & SkillsAPI & ClonesAPI & ImageAPI & CorporationAPI & AllianceAPI & LocationAPI & StatusAPI & WalletAPI

class APIClient: API {
	
	private var characterID: Int64? {
		return esi.token?.characterID
	}
	
	let esi: ESI
	
	init(esi: ESI) {
		self.esi = esi
	}
	
	//MARK: CharacterAPI

	func characterInformation(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Character.Information>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return characterInformation(with: id, cachePolicy: cachePolicy)
	}
	
	func characterInformation(with characterID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Character.Information>> {
		let esi = self.esi
		return esi.character.getCharactersPublicInformation(characterID: Int(characterID), cachePolicy: cachePolicy)
	}

	func blueprints(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Character.Blueprint]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let esi = self.esi
		return esi.character.getBlueprints(characterID: Int(id), cachePolicy: cachePolicy)
	}
	
	func character(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<Character>> {
		
		return Services.sde.performBackgroundTask{ [weak self] context -> ESI.Result<Character> in
			guard let strongSelf = self else {throw NCError.cancelled(type: APIClient.self, function: #function)}
			let (attributes, skills, skillQueue, implants) = try all(strongSelf.characterAttributes(cachePolicy: cachePolicy),
																	 strongSelf.skills(cachePolicy: cachePolicy),
																	 strongSelf.skillQueue(cachePolicy: cachePolicy),
																	 strongSelf.implants(cachePolicy: cachePolicy)).get()
			
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
			let expires = [attributes.expires, skills.expires, skillQueue.expires, implants.expires].compactMap {$0}.min()
			return ESI.Result(value: character, expires: expires)
		}
	}
	
	//MARK: SkillsAPI

	func characterAttributes(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Skills.CharacterAttributes>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.skills.getCharacterAttributes(characterID: Int(id), cachePolicy: cachePolicy)
	}
	
	func skillQueue(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Skills.SkillQueueItem]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.skills.getCharactersSkillQueue(characterID: Int(id), cachePolicy: cachePolicy)
	}
	
	func skills(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Skills.CharacterSkills>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.skills.getCharacterSkills(characterID: Int(id), cachePolicy: cachePolicy)
	}
	
	//MARK: ClonesAPI

	func implants(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[Int]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.clones.getActiveImplants(characterID: Int(id), cachePolicy: cachePolicy)
	}
	
	func clones(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Clones.JumpClones>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.clones.getClones(characterID: Int(id), cachePolicy: cachePolicy)
	}

	//MARK: ImageAPI

	func image(characterID: Int64, dimension: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<UIImage>> {
		return esi.image(characterID: Int(characterID), dimension: dimension * Int(UIScreen.main.scale), cachePolicy: cachePolicy)
			.then { result -> ESI.Result<UIImage> in
				return try result.map { value -> UIImage in
					guard let image = UIImage(data: value) else {throw NCError.invalidImageFormat}
					return image
				}
		}
	}
	
	func image(corporationID: Int64, dimension: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<UIImage>> {
		return esi.image(corporationID: Int(corporationID), dimension: dimension * Int(UIScreen.main.scale), cachePolicy: cachePolicy)
			.then { result -> ESI.Result<UIImage> in
				return try result.map { value -> UIImage in
					guard let image = UIImage(data: value) else {throw NCError.invalidImageFormat}
					return image
				}
		}
	}
	
	func image(allianceID: Int64, dimension: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<UIImage>> {
		return esi.image(allianceID: Int(allianceID), dimension: dimension * Int(UIScreen.main.scale), cachePolicy: cachePolicy)
			.then { result -> ESI.Result<UIImage> in
				return try result.map { value -> UIImage in
					guard let image = UIImage(data: value) else {throw NCError.invalidImageFormat}
					return image
				}
		}
	}
	
	func image(typeID: Int, dimension: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<UIImage>> {
		return esi.image(typeID: typeID, dimension: dimension * Int(UIScreen.main.scale), cachePolicy: cachePolicy)
			.then { result -> ESI.Result<UIImage> in
				return try result.map { value -> UIImage in
					guard let image = UIImage(data: value) else {throw NCError.invalidImageFormat}
					return image
				}
		}
	}

	//MARK: CorporationAPI

	func corporationInformation(corporationID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Corporation.Information>> {
		return esi.corporation.getCorporationInformation(corporationID: Int(corporationID), cachePolicy: cachePolicy)
	}
	
	func divisions(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Corporation.Divisions>> {
		return characterInformation(cachePolicy: cachePolicy).then { [weak self] result in
			guard let strongSelf = self else { throw NCError.cancelled(type: APIClient.self, function: #function)}
			return strongSelf.esi.corporation.getCorporationDivisions(corporationID: result.value.corporationID, cachePolicy: cachePolicy)
		}
	}
	
	//MARK: AllianceAPI
	
	func allianceInformation(allianceID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Alliance.Information>> {
		return esi.alliance.getAllianceInformation(allianceID: Int(allianceID), cachePolicy: cachePolicy)
	}
	
	//MARK: LocationAPI
	
	func characterLocation(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Location.CharacterLocation>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.location.getCharacterLocation(characterID: Int(id), cachePolicy: cachePolicy)
	}
	
	func characterShip(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Location.CharacterShip>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.location.getCurrentShip(characterID: Int(id), cachePolicy: cachePolicy)
	}

	//MARK: StatusAPI

	func serverStatus(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Status.ServerStatus>> {
		return esi.status.retrieveTheUptimeAndPlayerCounts(cachePolicy: cachePolicy)
	}
	
	//MARK: WalletAPI
	
	func walletBalance(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<Double>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.wallet.getCharactersWalletBalance(characterID: Int(id), cachePolicy: cachePolicy)
	}
	
	func walletJournal(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Wallet.WalletJournalItem]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.wallet.getCharacterWalletJournal(characterID: Int(id), cachePolicy: cachePolicy)
	}
	
	func walletTransactions(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Wallet.Transaction]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.wallet.getWalletTransactions(characterID: Int(id), cachePolicy: cachePolicy)
	}

}
