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
	func locations(ids: Set<Int64>) -> Future<[Int64: EVELocation]>
}

protocol StatusAPI: class {
	func serverStatus(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Status.ServerStatus>>
}

protocol WalletAPI: class {
	func walletBalance(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<Double>>
	func walletJournal(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Wallet.WalletJournalItem]>>
	func walletTransactions(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Wallet.Transaction]>>
}

protocol MarketAPI: class {
	func updateMarketPrices() -> Future<Bool>
	func prices(typeIDs: Set<Int>) -> Future<[Int: Double]>
	func marketHistory(typeID: Int, regionID: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Market.History]>>
	func marketOrders(typeID: Int, regionID: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Market.Order]>>
}

protocol UniverseAPI: class {
	func universeNames(ids: Set<Int64>) -> Future<ESI.Result<[ESI.Universe.Name]>>
	func universeStructure(structureID: Int64) -> Future<ESI.Result<ESI.Universe.StructureInformation>>
}

typealias API = CharacterAPI & SkillsAPI & ClonesAPI & ImageAPI & CorporationAPI & AllianceAPI & LocationAPI & StatusAPI & WalletAPI & MarketAPI & UniverseAPI

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
			guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
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
				let attributes = [SDEAttributeID.intelligenceBonus, SDEAttributeID.memoryBonus, SDEAttributeID.perceptionBonus, SDEAttributeID.willpowerBonus, SDEAttributeID.charismaBonus].lazy.map({($0, Int(type[$0]?.value ?? 0))})
				guard let value = attributes.first(where: {$0.1 > 0}) else {continue}
				augmentations[value.0] += value.1
			}
			
			var trainedSkills = Dictionary(skills.value.skills.map { ($0.skillID, $0)}, uniquingKeysWith: {
				$0.trainedSkillLevel > $1.trainedSkillLevel ? $0 : $1
			})
			
			let currentDate = Date()
			var validSkillQueue = skillQueue.value.filter{$0.finishDate != nil}
			let i = validSkillQueue.partition(by: {$0.finishDate! > currentDate})
			for skill in validSkillQueue[..<i] {
				guard let endSP = skill.levelEndSP ?? context.invType(skill.skillID).flatMap({Character.Skill(type: $0)})?.skillPoints(at: skill.finishedLevel) else {continue}
				
				let skill = ESI.Skills.CharacterSkills.Skill(activeSkillLevel: skill.finishedLevel, skillID: skill.skillID, skillpointsInSkill: Int64(endSP), trainedSkillLevel: skill.finishedLevel)
				trainedSkills[skill.skillID] = trainedSkills[skill.skillID].map {$0.trainedSkillLevel > skill.trainedSkillLevel ? $0 : skill} ?? skill
			}
			
			let sq = validSkillQueue[i...].sorted{$0.queuePosition < $1.queuePosition}.compactMap { i -> Character.SkillQueueItem? in
				guard let type = context.invType(i.skillID), let skill = Character.Skill(type: type) else {return nil}
				let item = Character.SkillQueueItem(skill: skill, queuedSkill: i)
				trainedSkills[i.skillID]?.skillpointsInSkill = Int64(item.skillPoints)
				return item
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
			guard let strongSelf = self else { throw NCError.cancelled(type: type(of: self), function: #function)}
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
	
	lazy var cachedLocations: Atomic<[Int64: EVELocation]> = Atomic([:])

	func locations(ids: Set<Int64>) -> Future<[Int64: EVELocation]> {
		guard !ids.isEmpty else { return .init([:]) }
		
		var cachedLocations = self.cachedLocations.value
		
		let progress = Progress(totalUnitCount: Int64(ids.count))
		
		return Services.sde.performBackgroundTask{ [weak self] context -> [Int64: EVELocation] in
			guard let strongSelf = self else {return [:]}
			
			var locations = [Int64: EVELocation]()
			var missing = Set<Int64>()
			var structures = Set<Int64>()

			for id in ids {
				if let location = cachedLocations[id] {
					locations[id] = location
					progress.completedUnitCount += 1
				}
				else if id > Int64(Int32.max) {
					structures.insert(id)
				}
				else if (66000000 < id && id < 66014933) { //staStations
					if let id = Int(exactly: id), let station = context.staStation(id - 6000001) {
						let location = EVELocation(station)
						locations[Int64(id)] = location
						cachedLocations[Int64(id)] = location
						progress.completedUnitCount += 1
					}
					else {
						missing.insert(id)
					}
				}
				else if (60000000 < id && id < 61000000) { //staStations
					if let id = Int(exactly: id), let station = context.staStation(id) {
						let location = EVELocation(station)
						locations[Int64(id)] = location
						cachedLocations[Int64(id)] = location
						progress.completedUnitCount += 1
					}
					else {
						missing.insert(id)
					}
				}
				else {
					missing.insert(id)
				}
			}
			
			if !missing.isEmpty {
				progress.performAsCurrent(withPendingUnitCount: Int64(missing.count)) {
					try? strongSelf.universeNames(ids: missing).get().value.forEach { name in
						guard let location = EVELocation(name) else {return}
						locations[Int64(name.id)] = location
						cachedLocations[Int64(name.id)] = location
					}
				}
			}
			
			if !structures.isEmpty {
				let structures = Array(structures)
				let futures = any(structures.map { id in progress.performAsCurrent(withPendingUnitCount: 1) { strongSelf.universeStructure(structureID: id) } })
				try? zip(structures, futures.get()).forEach { (id, value) in
					guard let value = value?.value else {return}
					let location = EVELocation(value)
					locations[id] = location
					cachedLocations[id] = location
				}
			}
			return locations
		}.finally(on: .main) { [weak self] in
			self?.cachedLocations.value = cachedLocations
		}
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

	//MARK: MarketAPI
	
	func updateMarketPrices() -> Future<Bool> {
		let esi = self.esi
		return Services.cache.performBackgroundTask { context -> Bool in
			let prices = try? esi.market.listMarketPrices(cachePolicy: .returnCacheDataDontLoad).get()
			if let expires = prices?.expires, expires > Date() {
				return false
			}
			else {
				let prices = try esi.market.listMarketPrices(cachePolicy: .reloadIgnoringLocalCacheData).get()
				
				let new = Dictionary(prices.value.map {(Int32($0.typeID), $0)}, uniquingKeysWith: {lhs, _ in lhs})
				let old = (context.prices()?.map {($0.typeID, $0)}).map { Dictionary($0, uniquingKeysWith: {lhs, _ in lhs}) } ?? [:]
				
				let newKeys = Set(new.keys)
				let oldkeys = Set(old.keys)
				
				for key in oldkeys.subtracting(newKeys) {
					guard let object = old[key] else {continue}
					context.managedObjectContext.delete(object)
				}
				
				for key in newKeys.subtracting(oldkeys) {
					let price = Price(context: context.managedObjectContext)
					price.typeID = key
					price.price = new[key]?.averagePrice ?? 0
				}
				
				for key in newKeys.intersection(oldkeys) {
					let price = old[key]
					price?.price = new[key]?.averagePrice ?? 0
				}
				
				return true
			}
		}
	}
	
	func prices(typeIDs: Set<Int>) -> Future<[Int: Double]> {
		return Services.cache.performBackgroundTask { context -> Future<[Int: Double]> in
			if let prices = context.price(for: typeIDs), !prices.isEmpty {
				return .init(prices)
			}
			else if try context.managedObjectContext.from(Price.self).count() == 0 {
				return self.updateMarketPrices().then { _ in
					return Services.cache.performBackgroundTask { context -> [Int: Double] in
						return context.price(for: typeIDs) ?? [:]
					}
				}
			}
			else {
				return .init([:])
			}
		}
	}
	
	func marketHistory(typeID: Int, regionID: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Market.History]>> {
		return esi.market.listHistoricalMarketStatisticsInRegion(regionID: regionID, typeID: typeID, cachePolicy: cachePolicy)
	}
	
	func marketOrders(typeID: Int, regionID: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Market.Order]>> {
		return esi.market.listOrdersInRegion(orderType: .all, regionID: regionID, typeID: typeID, cachePolicy: cachePolicy)
	}
	
	//MARK: UniverseAPI
	
	func universeNames(ids: Set<Int64>) -> Future<ESI.Result<[ESI.Universe.Name]>> {
		let ids = ids.map{Int($0)}.sorted()
		return esi.universe.getNamesAndCategoriesForSetOfIDs(ids: ids)
	}
	
	func universeStructure(structureID: Int64) -> Future<ESI.Result<ESI.Universe.StructureInformation>> {
		return esi.universe.getStructureInformation(structureID: structureID)
	}


}
