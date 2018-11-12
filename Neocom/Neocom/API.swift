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
import CoreData

protocol ESIResultProtocol {
	associatedtype Value
	var value: Value {get}
	var expires: Date? {get}
}

extension ESI.Result: ESIResultProtocol {
	func map<T>(_ transform: (Value) throws -> T) rethrows -> ESI.Result<T> {
		return try ESI.Result<T>(value: transform(value), expires: expires, metadata: metadata)
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
	func locations(with ids: Set<Int64>) -> Future<[Int64: EVELocation]>
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
	func openOrders(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Market.CharacterOrder]>>
}

protocol UniverseAPI: class {
	func universeNames(ids: Set<Int64>) -> Future<ESI.Result<[ESI.Universe.Name]>>
	func universeStructure(structureID: Int64) -> Future<ESI.Result<ESI.Universe.StructureInformation>>
}

protocol MailAPI: class {
	func sendMail(body: String, subject: String, recipients: [ESI.Mail.Recipient]) -> Future<ESI.Result<Int>>
	func mailHeaders(lastMailID: Int64?, labels: [Int64]?, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Mail.Header]>>
	func mailBody(mailID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Mail.MailBody>>
	func mailingLists(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Mail.Subscription]>>
	func mailLabels(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Mail.MailLabelsAndUnreadCounts>>
	func markRead(mail: ESI.Mail.Header) -> Future<ESI.Result<String>>
	func delete(mailID: Int64) -> Future<ESI.Result<String>>
}

protocol SearchAPI: class {
	func search(_ string: String, categories: [ESI.Search.Categories], strict: Bool, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Search.SearchResult>>
	func contacts(with ids: Set<Int64>) -> Future<[Int64: Contact]>
	func searchContacts(_ string: String, categories: [ESI.Search.Categories]) -> Future<[Int64: Contact]>
}

protocol IncursionsAPI: class {
	func incursions(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Incursions.Incursion]>>
}

protocol AssetsAPI: class {
	func assets(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Assets.Asset]>>
	func assetNames(with ids: Set<Int64>, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[Int64: ESI.Assets.Name]>>
}

protocol IndustryAPI: class {
	func industryJobs(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Industry.Job]>>
}

protocol ContractsAPI: class {
	func contracts(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Contract]>>
	func contractItems(contractID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Item]>>
	func contractBids(contractID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Bid]>>
}

extension SearchAPI {
	func search(_ string: String, categories: [ESI.Search.Categories], cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Search.SearchResult>> {
		return search(string, categories: categories, strict: false, cachePolicy: cachePolicy)
	}
}

typealias API = CharacterAPI & SkillsAPI & ClonesAPI & ImageAPI & CorporationAPI & AllianceAPI & LocationAPI & StatusAPI & WalletAPI & MarketAPI & UniverseAPI & MailAPI & SearchAPI & IncursionsAPI & AssetsAPI & IndustryAPI & ContractsAPI

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
			
			let character = Character(attributes: attributes.value,
									  skills: skills.value,
									  skillQueue: skillQueue.value,
									  implants: implants.value,
									  context: context)
			
			let expires = [attributes.expires, skills.expires, skillQueue.expires, implants.expires].compactMap {$0}.min()
			return ESI.Result(value: character, expires: expires, metadata: nil)
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
	
	private lazy var cachedLocations: Atomic<[Int64: EVELocation]> = Atomic([:])

	func locations(with ids: Set<Int64>) -> Future<[Int64: EVELocation]> {
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
	
	func openOrders(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Market.CharacterOrder]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.market.listOpenOrdersFromCharacter(characterID: Int(id), cachePolicy: cachePolicy)
	}
	
	//MARK: UniverseAPI
	
	func universeNames(ids: Set<Int64>) -> Future<ESI.Result<[ESI.Universe.Name]>> {
		guard !ids.isEmpty else { return .init(ESI.Result(value: [], expires: nil, metadata: nil)) }
		let progress = Progress(totalUnitCount: Int64(ids.count))
		let esi = self.esi
		
		return DispatchQueue.global(qos: .utility).async { () -> ESI.Result<[ESI.Universe.Name]> in
			let ids = ids.map{Int($0)}.sorted()
			let chunks = stride(from: 0, to: ids.count, by: 1000).map { ids[$0..<min(ids.count, $0 + 1000)] }
			
			let results = try all(chunks.map { i in
				progress.performAsCurrent(withPendingUnitCount: Int64(i.count)) {
					esi.universe.getNamesAndCategoriesForSetOfIDs(ids: Array(i))
				}
			}).get()
			guard let first = results.first else { return ESI.Result(value: [], expires: nil, metadata: nil) }
			
			return first.map { _ in results.flatMap{$0.value}}
		}
	}
	
	func universeStructure(structureID: Int64) -> Future<ESI.Result<ESI.Universe.StructureInformation>> {
		return esi.universe.getStructureInformation(structureID: structureID)
	}

	//MARK: MailAPI
	
	func sendMail(body: String, subject: String, recipients: [ESI.Mail.Recipient]) -> Future<ESI.Result<Int>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		let mail = ESI.Mail.NewMail(approvedCost: nil, body: body, recipients: recipients, subject: subject)
		return esi.mail.sendNewMail(characterID: Int(id), mail: mail)
	}
	
	func mailHeaders(lastMailID: Int64?, labels: [Int64]?, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Mail.Header]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.mail.returnMailHeaders(characterID: Int(id), labels: labels?.map{Int($0)}, lastMailID: lastMailID.map{Int($0)}, cachePolicy: cachePolicy)
	}
	
	func mailBody(mailID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Mail.MailBody>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.mail.returnMail(characterID: Int(id), mailID: Int(mailID), cachePolicy: cachePolicy)
	}
	
	func mailingLists(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Mail.Subscription]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.mail.returnMailingListSubscriptions(characterID: Int(id), cachePolicy: cachePolicy)
	}
	
	func mailLabels(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Mail.MailLabelsAndUnreadCounts>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.mail.getMailLabelsAndUnreadCounts(characterID: Int(id), cachePolicy: cachePolicy)
	}

	func markRead(mail: ESI.Mail.Header) -> Future<ESI.Result<String>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		guard let mailID = mail.mailID else { return .init(.failure(NCError.invalidArgument(type: type(of: self), function: #function, argument: "mail", value: mail))) }
		let contents = ESI.Mail.UpdateContents(labels: mail.labels, read: true)
		return esi.mail.updateMetadataAboutMail(characterID: Int(id), contents: contents, mailID: mailID)
	}
	
	func delete(mailID: Int64) -> Future<ESI.Result<String>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.mail.deleteMail(characterID: Int(id), mailID: Int(mailID))
	}
	
	//MARK: SearchAPI
	func search(_ string: String, categories: [ESI.Search.Categories], strict: Bool, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Search.SearchResult>> {
		return esi.search.search(categories: categories, search: string, strict: strict, cachePolicy: cachePolicy)
	}

	private lazy var cachedContacts = [Int64: Contact]()
	private lazy var invalidIDs = Atomic<Set<Int64>>(Set())
	
	func contacts(with ids: Set<Int64>) -> Future<[Int64: Contact]> {
		let ids = ids.subtracting(invalidIDs.value)
		var result = Dictionary(ids.compactMap {cachedContacts[$0]}.map{($0.contactID, $0)}, uniquingKeysWith: {(a, _) in a})
		var missing = ids.subtracting(Set(result.keys))
		
		if missing.isEmpty {
			return .init(result)
		}
		else {
			return Services.cache.performBackgroundTask { [weak self] context -> [NSManagedObjectID] in
				var contacts = context.contacts(with: missing) ?? [:]
				missing.subtract(contacts.keys)
				
				if !missing.isEmpty, let mailingLists = (try? self?.mailingLists(cachePolicy: .useProtocolCachePolicy).get().value) ?? nil {
					mailingLists.filter {missing.contains(Int64($0.mailingListID))}.forEach { i in
						let contact = Contact(context: context.managedObjectContext)
						contact.contactID = Int64(i.mailingListID)
						contact.category = ESI.Mail.Recipient.RecipientType.mailingList.rawValue
						contact.name = i.name
						contacts[contact.contactID] = contact
						missing.remove(contact.contactID)
					}
				}

				
				if !missing.isEmpty {
					do {
						let universeNames = try self?.universeNames(ids: missing).get().value
						universeNames?.forEach { name in
							let contact = Contact(context: context.managedObjectContext)
							contact.contactID = Int64(name.id)
							contact.category = name.category.rawValue
							contact.name = name.name
							contacts[contact.contactID] = contact
							missing.remove(contact.contactID)
						}
					}
					catch {
						if (error as? AFError)?.responseCode == 404 {
							self?.invalidIDs.perform {$0.formUnion(missing)}
						}
					}
				}
				try? context.save()
				return contacts.values.map{$0.objectID}
			}.then(on: .main) { [weak self] ids -> [Int64: Contact] in
				let context = Services.cache.viewContext
				let contacts = ids.compactMap { objectID -> Contact? in (try? context.existingObject(with: objectID)) ?? nil }
				contacts.forEach {
					result[$0.contactID] = $0
					self?.cachedContacts[$0.contactID] = $0
				}
				return result
			}
		}
	}

	func searchContacts(_ string: String, categories: [ESI.Search.Categories]) -> Future<[Int64: Contact]> {
		let progress = Progress(totalUnitCount: 2)
		return progress.performAsCurrent(withPendingUnitCount: 1) {
			self.search(string, categories: categories, cachePolicy: .useProtocolCachePolicy).then { [weak self] result -> Future<[Int64: Contact]> in
				guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
				var ids = Set<Int>()
				let searchResult = result.value
				ids.formUnion(searchResult.agent ?? [])
				ids.formUnion(searchResult.alliance ?? [])
				ids.formUnion(searchResult.character ?? [])
				ids.formUnion(searchResult.constellation ?? [])
				ids.formUnion(searchResult.corporation ?? [])
				ids.formUnion(searchResult.faction ?? [])
				ids.formUnion(searchResult.inventoryType ?? [])
				ids.formUnion(searchResult.region ?? [])
				ids.formUnion(searchResult.solarSystem ?? [])
				ids.formUnion(searchResult.station ?? [])
				return progress.performAsCurrent(withPendingUnitCount: 1) {
					strongSelf.contacts(with: Set(ids.map{Int64($0)}))
				}
			}
		}
	}

	//MARK: IncursionsAPI
	func incursions(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Incursions.Incursion]>> {
		return esi.incursions.listIncursions(cachePolicy: cachePolicy)
	}

	//MARK: AssetsAPI
//	func assets(page: Int?, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Assets.Asset]>> {
//		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
//		assert(page != 0)
//		return esi.assets.getCharacterAssets(characterID: Int(id), page: page, cachePolicy: cachePolicy)
//	}
	
	func assets(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Assets.Asset]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }

		let esi = self.esi
		let progress = Progress(totalUnitCount: 2)
		return DispatchQueue.global(qos: .utility).async { () -> ESI.Result<[ESI.Assets.Asset]> in
			let id = Int(id)
			
			let firstPage = try progress.performAsCurrent(withPendingUnitCount: 1) { esi.assets.getCharacterAssets(characterID: id, page: nil, cachePolicy: cachePolicy) }.get()
			let numberOfPages = firstPage.metadata?["x-pages"].flatMap{Int($0)} ?? 1
			
			let assets: [ESI.Assets.Asset]
			
			if numberOfPages > 1 {
				let partialProgress = progress.performAsCurrent(withPendingUnitCount: 1) {Progress(totalUnitCount: Int64(numberOfPages - 1))}
				let pages = try any((2...numberOfPages).map{ i in partialProgress.performAsCurrent(withPendingUnitCount: 1) { esi.assets.getCharacterAssets(characterID: id, page: i, cachePolicy: cachePolicy) } }).get().compactMap {$0}
				
				assets = pages.flatMap{$0.value}
			}
			else {
				assets = []
			}
			
			return firstPage.map {
				Set($0 + assets).filter({$0.locationFlag != .skill && $0.locationFlag != .implant})
			}
		}
	}
	
	func assetNames(with ids: Set<Int64>, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[Int64: ESI.Assets.Name]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		guard !ids.isEmpty else { return .init(ESI.Result(value: [:], expires: nil, metadata: nil)) }
		let progress = Progress(totalUnitCount: Int64(ids.count))
		let esi = self.esi
		
		return DispatchQueue.global(qos: .utility).async { () -> ESI.Result<[Int64: ESI.Assets.Name]> in
			let ids = ids.sorted()
			let chunks = stride(from: 0, to: ids.count, by: 1000).map { ids[$0..<min(ids.count, $0 + 1000)] }
			
			let results = try any(chunks.map { i in
				progress.performAsCurrent(withPendingUnitCount: Int64(i.count)) {
					esi.assets.getCharacterAssetNames(characterID: Int(id), itemIds: Array(i))
				}
			}).get().compactMap{$0}
			guard let first = results.first else { return ESI.Result(value: [:], expires: nil, metadata: nil) }
			let values = Dictionary(results.flatMap{$0.value}.map{($0.itemID, $0)}, uniquingKeysWith: {a, _ in a})
			
			return first.map { _ in values}
		}
	}
	
	//MARK: IndustryAPI
	
	func industryJobs(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Industry.Job]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.industry.listCharacterIndustryJobs(characterID: Int(id), includeCompleted: true, cachePolicy: cachePolicy)
	}

	//MARK: ContractsAPI
	
	func contracts(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Contract]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.contracts.getContracts(characterID: Int(id), cachePolicy: cachePolicy)
	}
	
	func contractItems(contractID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Item]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.contracts.getContractItems(characterID: Int(id), contractID: Int(contractID), cachePolicy: cachePolicy)
	}
	
	func contractBids(contractID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Contracts.Bid]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.contracts.getContractBids(characterID: Int(id), contractID: Int(contractID), cachePolicy: cachePolicy)

	}

	
}
