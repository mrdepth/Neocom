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
	func image(contact: Contact, dimension: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<UIImage>>
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
	func search(_ string: String, categories: [ESI.Search.SearchCategories], strict: Bool, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Search.SearchResult>>
	func contacts(with ids: Set<Int64>) -> Future<[Int64: Contact]>
	func searchContacts(_ string: String, categories: [ESI.Search.SearchCategories]) -> Future<[Int64: Contact]>
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

protocol KillmailsAPI: class {
	func killmails(page: Int?, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Killmails.Recent]>>
	func killmailInfo(killmailHash: String, killmailID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Killmails.Killmail>>
	func zKillmails(filter: [EVEAPI.ZKillboard.Filter], page: Int?, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[EVEAPI.ZKillboard.Killmail]>>
}

extension SearchAPI {
	func search(_ string: String, categories: [ESI.Search.SearchCategories], cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Search.SearchResult>> {
		return search(string, categories: categories, strict: false, cachePolicy: cachePolicy)
	}
}

protocol BaseAPI {
	init(esi: ESI)
}

typealias API = BaseAPI & CharacterAPI & SkillsAPI & ClonesAPI & ImageAPI & CorporationAPI & AllianceAPI & LocationAPI & StatusAPI & WalletAPI & MarketAPI & UniverseAPI & MailAPI & SearchAPI & IncursionsAPI & AssetsAPI & IndustryAPI & ContractsAPI & KillmailsAPI

class APIClient: API {
	
	private var characterID: Int64? {
		return esi.token?.characterID
	}
	
	let esi: ESI
	lazy var zKillboard = EVEAPI.ZKillboard()
	
	required init(esi: ESI) {
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
	
	func image(contact: Contact, dimension: Int, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<UIImage>> {
		switch contact.recipientType {
		case .character?:
			return image(characterID: contact.contactID, dimension: dimension, cachePolicy: .useProtocolCachePolicy)
		case .corporation?:
			return image(corporationID: contact.contactID, dimension: dimension, cachePolicy: .useProtocolCachePolicy)
		case .alliance?:
			return image(allianceID: contact.contactID, dimension: dimension, cachePolicy: .useProtocolCachePolicy)
		default:
			return .init(ESI.Result(value: UIImage(), expires: Date(timeIntervalSinceNow: 3600), metadata: nil))
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
	func search(_ string: String, categories: [ESI.Search.SearchCategories], strict: Bool, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Search.SearchResult>> {
		return esi.search.search(categories: categories, search: string, strict: strict, cachePolicy: cachePolicy)
	}

	private lazy var cachedContacts = [Int64: Contact]()
	private lazy var invalidIDs = Atomic<Set<Int64>>(Set())
	
	func contacts(with ids: Set<Int64>) -> Future<[Int64: Contact]> {
		let ids = ids.subtracting(invalidIDs.value)
		
		var result = Dictionary(cachedContacts.filter {ids.contains($0.key)}, uniquingKeysWith: {(a, _) in a})
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
				
				while true {
					do {
						try context.save()
						break
					}
					catch {
						if let error = error as? CocoaError,
							error.errorCode == CocoaError.managedObjectConstraintMerge.rawValue,
							let conflicts = error.errorUserInfo[NSPersistentStoreSaveConflictsErrorKey] as? [NSConstraintConflict],
							!conflicts.isEmpty {
							
							let pairs = conflicts.filter{$0.databaseObject is Contact}.map { conflict in
								(conflict.databaseObject as! Contact, Set(conflict.conflictingObjects.compactMap{$0 as? Contact}))
							}.filter{!$0.1.isEmpty}
							
							if !pairs.isEmpty {
								for (object, objects) in pairs {
									contacts.filter{objects.contains($0.value)}.forEach {
										contacts[$0.key] = object
									}
									objects.forEach {
										$0.managedObjectContext?.delete($0)
									}
								}
							}
							else {
								break
							}
						}
						else {
							break
						}
					}
				}
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

	func searchContacts(_ string: String, categories: [ESI.Search.SearchCategories]) -> Future<[Int64: Contact]> {
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

	//MARK: KillmailsAPI
	
	func killmails(page: Int?, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[ESI.Killmails.Recent]>> {
		guard let id = characterID else { return .init(.failure(NCError.missingCharacterID(function: #function))) }
		return esi.killmails.getCharactersRecentKillsAndLosses(characterID: Int(id), page: page, cachePolicy: cachePolicy)
		
/*		let killmails = [[ESI.Killmails.Recent(killmailHash: "efdb83e99260384589123b1a57a3655de3641937", killmailID: 45560841),
						  ESI.Killmails.Recent(killmailHash: "f8ffc770033a08e65a34632dedad0e31e72f17d5", killmailID: 45560150),
						  ESI.Killmails.Recent(killmailHash: "29ad254d50bf5441ad9bc88905ba70f538f92b5d", killmailID: 45560149),
						  ESI.Killmails.Recent(killmailHash: "454fb2665b2a0b3caf79d514c8e243698dc5c450", killmailID: 41319377),
						  ESI.Killmails.Recent(killmailHash: "179c08c241c44708345bbfba16dbd5c2c0c92672", killmailID: 22855674),
						  ESI.Killmails.Recent(killmailHash: "9391667ed550122012a4c5c905c7125be6e9b390", killmailID: 22855653),
						  ESI.Killmails.Recent(killmailHash: "7461ee7dc068a5a8e38b7a33c86d5a1daf42eaa6", killmailID: 22555322),
						  ESI.Killmails.Recent(killmailHash: "ead9868acb601ad5c5ccbac55c9540d89fd907b7", killmailID: 22425400),
						  ESI.Killmails.Recent(killmailHash: "9a8ff6cb0a263c22cbd061a0e7ad46c7dbd8c273", killmailID: 22425359),
						  ESI.Killmails.Recent(killmailHash: "0d43aa624ed5ffbf96093fe1369987068d57c2d6", killmailID: 22271902),
						  ESI.Killmails.Recent(killmailHash: "c9e56846f73b4cb82c3868e91d173bec99c7d630", killmailID: 22044992),
						  ESI.Killmails.Recent(killmailHash: "328acec61a214a767fe0c4b113770fe5bdc29bd6", killmailID: 21694267),
						  ESI.Killmails.Recent(killmailHash: "199cf3e15eb0838e12fdb14441b32148dab9485a", killmailID: 21692061),
						  ESI.Killmails.Recent(killmailHash: "8e0b0178c8b66df32f337713bd344b0ca92f7308", killmailID: 21580394),
						  ESI.Killmails.Recent(killmailHash: "161093ae9991927f77f3af02a82b7c945a560698", killmailID: 21580365),
						  ESI.Killmails.Recent(killmailHash: "d396c18bfd7ba8a7720066f8553120f208ed1508", killmailID: 20670536),
						  ESI.Killmails.Recent(killmailHash: "ad5d689c6c454e6a433a547a9669fef39e34402d", killmailID: 20651988),
						  ESI.Killmails.Recent(killmailHash: "cfdf3fcd83d5a970148ce51272d5ead21db7a7ee", killmailID: 20651966),
						  ESI.Killmails.Recent(killmailHash: "d7df6240cee794710839b78da936d8f6a1c33f65", killmailID: 20651176),
			ESI.Killmails.Recent(killmailHash: "5da34e22ad57076268245d81259bf493e099ed29", killmailID: 20528926)],
						 [ESI.Killmails.Recent(killmailHash: "8cb34090a8421573f04b01e494ef95e5a45ac52d", killmailID: 20260582),
						  ESI.Killmails.Recent(killmailHash: "0b9f0b0e795cd96ea4b538f6252788f2e5d78b78", killmailID: 20235343),
						  ESI.Killmails.Recent(killmailHash: "25d09ce03d6aee6ace8923c127882f04595cf1d9", killmailID: 20094091),
						  ESI.Killmails.Recent(killmailHash: "d50706f96ee2125237727d80936117fab87cafef", killmailID: 20094083),
						  ESI.Killmails.Recent(killmailHash: "0240a30a4d3e66030108f084463ad0ac582f0768", killmailID: 20093815),
						  ESI.Killmails.Recent(killmailHash: "ed40e7c62b5425f969c06db9f230272e139f71d6", killmailID: 20093713),
						  ESI.Killmails.Recent(killmailHash: "d789d850011401db7fe5d886ebbd2f2a3463d8a8", killmailID: 20017378),
						  ESI.Killmails.Recent(killmailHash: "8e9569109a1b71390cf2b1584ccd34a4956fb3dc", killmailID: 20017253),
						  ESI.Killmails.Recent(killmailHash: "85f9e729baa46c472d93eee77fac8317324d090a", killmailID: 20017250),
						  ESI.Killmails.Recent(killmailHash: "661a5e01fc2fa5aa3921b1ff96deacf136e4c8a8", killmailID: 20017167),
						  ESI.Killmails.Recent(killmailHash: "f1ce232dafee19a098d2fe50fd7a5ab83dd030ab", killmailID: 20016632),
						  ESI.Killmails.Recent(killmailHash: "f7863fe81b5ede0ffce60a709afad81bdb6d923a", killmailID: 20016615),
						  ESI.Killmails.Recent(killmailHash: "51d02e4807418d2c16b880d388531a4895206dfa", killmailID: 20016507),
						  ESI.Killmails.Recent(killmailHash: "0141d78545a5d88de0d03ec28f970190616d9cd3", killmailID: 20016494),
						  ESI.Killmails.Recent(killmailHash: "688a576aafce981fe1015d0a0cb494833e888edb", killmailID: 20016457),
						  ESI.Killmails.Recent(killmailHash: "d0233fe4f31b33819c5aa1cafd626df215288ac1", killmailID: 20016448),
						  ESI.Killmails.Recent(killmailHash: "8d7e100bf72ef7f1b4400d8511767cdd12c456d3", killmailID: 20015608),
						  ESI.Killmails.Recent(killmailHash: "32e141f06bb900da2495eab525acc5ffa81dc3c4", killmailID: 20006134),
						  ESI.Killmails.Recent(killmailHash: "88ee0b163878c6270117b019dede18305db66f4d", killmailID: 20006102),
							ESI.Killmails.Recent(killmailHash: "79e01350497c7263c132e051188acb78b546e676", killmailID: 20004908)],
						 [ESI.Killmails.Recent(killmailHash: "5eb318ddf1c29554ad58f8e950a87f2d646c7b27", killmailID: 20004886),
						  ESI.Killmails.Recent(killmailHash: "442f9a058fe34bba9766f3be810e6dfa04686d5c", killmailID: 19993060),
						  ESI.Killmails.Recent(killmailHash: "6b436f8345450f0bb9da9fa1b8b095a56a0dc0ec", killmailID: 19993055),
						  ESI.Killmails.Recent(killmailHash: "e22b413fcdf2a930dbd4da6d35f0632272aa43b8", killmailID: 19993015),
						  ESI.Killmails.Recent(killmailHash: "b647257c51f32049336d0c6b99929d485b21ba65", killmailID: 19992787),
						  ESI.Killmails.Recent(killmailHash: "5ae2443cd77eeca2a6a363d33bbd757b720a03d4", killmailID: 19992540),
						  ESI.Killmails.Recent(killmailHash: "d6df5de283ecdb04ade71294e11652a07261790d", killmailID: 19992388),
						  ESI.Killmails.Recent(killmailHash: "a95c9bd3ee93df4db9d673170a5ab97b3d946972", killmailID: 19992118),
						  ESI.Killmails.Recent(killmailHash: "95691e8dc6db2ef2efa1541f488d9aa017b15277", killmailID: 19991553),
						  ESI.Killmails.Recent(killmailHash: "cb9e78594e413e05f91d3ecfcc82d887bbffd411", killmailID: 19991494),
						  ESI.Killmails.Recent(killmailHash: "5053e3ce7378ad770c721cf97110a10c17166aed", killmailID: 19991490),
						  ESI.Killmails.Recent(killmailHash: "ebd41809beb716489c63d5a61c1b00154195c180", killmailID: 19990541),
						  ESI.Killmails.Recent(killmailHash: "0b956c3b565a06cfba6dc90bf9e97adf34003256", killmailID: 19990524),
						  ESI.Killmails.Recent(killmailHash: "62b40223aaaacc1bd45ab2ac0fa511a25e4a10f8", killmailID: 19723501),
						  ESI.Killmails.Recent(killmailHash: "f384e8f72f41a9b5e26bd6c6e1e7a26e5dc9cf6c", killmailID: 19722359),
						  ESI.Killmails.Recent(killmailHash: "2115e5c5b611dfc131e074d77075863c5bcddec7", killmailID: 19228046),
						  ESI.Killmails.Recent(killmailHash: "333f2815bd7bbc1f5c84e2b12ce0f092ad532ee3", killmailID: 19228006),
						  ESI.Killmails.Recent(killmailHash: "2edb2248c9bb38aff537972adff73b3949b1ed98", killmailID: 19227820),
						  ESI.Killmails.Recent(killmailHash: "5fd09a102de306e540ea81ef29abfc2b9ccc5cfe", killmailID: 19227793),
							ESI.Killmails.Recent(killmailHash: "edce860bcd4e091740fed7cb7969be6dbe9be06c", killmailID: 19227706)],
						 [ESI.Killmails.Recent(killmailHash: "ad32a8d373881eda8adcb17567c175b7ff6995e5", killmailID: 19227673),
						  ESI.Killmails.Recent(killmailHash: "6951ede344b33a90a29f6c6ad21e8971d7a8e4cb", killmailID: 19227628),
						  ESI.Killmails.Recent(killmailHash: "c6b2db007029c574be635df9467beabf6ed7416d", killmailID: 19227086),
						  ESI.Killmails.Recent(killmailHash: "ac1f466158cdcc6d8437ad2517a78d0db7d7ffe8", killmailID: 19226715),
						  ESI.Killmails.Recent(killmailHash: "b38663844fc538c3d631f56e0ccf18a05031be2f", killmailID: 19226676),
						  ESI.Killmails.Recent(killmailHash: "42dc609a48f66ab76c1e66b4d93b158cd4eb64c8", killmailID: 19226583),
						  ESI.Killmails.Recent(killmailHash: "c7858520df56383719a8d67ecbc1cee69ae5c9ab", killmailID: 18702408),
						  ESI.Killmails.Recent(killmailHash: "e2383e281d4002066b7e6f4318b7c48aaf58c971", killmailID: 18549694),
						  ESI.Killmails.Recent(killmailHash: "d7c1e7ffb52e2bf1993fcbfed85754a009d6c77e", killmailID: 18456533),
						  ESI.Killmails.Recent(killmailHash: "55ca2684d1452181006c28074867b345e74d895f", killmailID: 18266339),
						  ESI.Killmails.Recent(killmailHash: "6792608440c49ab0c6f6862510403ca99189176c", killmailID: 18266334),
						  ESI.Killmails.Recent(killmailHash: "e91a034a5787d18e9338d4ae1d8c533e5bc29932", killmailID: 18192425),
						  ESI.Killmails.Recent(killmailHash: "069927b0061e3adcd6af3496f4ba37fd4163979b", killmailID: 18160202),
						  ESI.Killmails.Recent(killmailHash: "4930d269c28379776814cb6c17f7094949982301", killmailID: 18047929),
						  ESI.Killmails.Recent(killmailHash: "dcc57407358b88ee0874002655173fbd01abc3ff", killmailID: 18047747),
						  ESI.Killmails.Recent(killmailHash: "45d127eae96d99c861741af961ef2ea462a58c6a", killmailID: 18047492),
						  ESI.Killmails.Recent(killmailHash: "f5cf3b801b15f6bef92ca28fafee07b2cb29892f", killmailID: 18046284),
						  ESI.Killmails.Recent(killmailHash: "39f339e0220d8864f7dd53296d2ea66be9e2f861", killmailID: 17929797),
						  ESI.Killmails.Recent(killmailHash: "b51aed7c724f8fc4194c6300c41f36e716af04f1", killmailID: 17912469),
							ESI.Killmails.Recent(killmailHash: "988d7ee16d4621eb1e5ba3340aafe99887fa7288", killmailID: 17911835)],
						 [ESI.Killmails.Recent(killmailHash: "fa31d3951b476a9abb4e8a836677400c632011ba", killmailID: 17909861),
						  ESI.Killmails.Recent(killmailHash: "292dc20ea99dd4ba6301a8d3d6c7fafd29ca0479", killmailID: 17823858),
						  ESI.Killmails.Recent(killmailHash: "9abfa64d07da6466fec807e38ba346ad6ef680fb", killmailID: 17753934),
						  ESI.Killmails.Recent(killmailHash: "cca4e388e5b4811a5867b102597d805c18a8c643", killmailID: 17357983),
						  ESI.Killmails.Recent(killmailHash: "0856af7ac76b89b2bb591a6395a2473435a4649d", killmailID: 17357968),
						  ESI.Killmails.Recent(killmailHash: "5ad136f4beaccab409d2ab83f748c1f43145bc9c", killmailID: 17216734),
						  ESI.Killmails.Recent(killmailHash: "5ace5d23c3c26e21833aee614674b15dc302dbf1", killmailID: 17199050),
						  ESI.Killmails.Recent(killmailHash: "ebdd139bfb95dc5ef7ec9f263b21a244997765e3", killmailID: 17198997),
						  ESI.Killmails.Recent(killmailHash: "fbdf389a04ef73bfe01c675c7689c7bf76a9902a", killmailID: 17197288),
						  ESI.Killmails.Recent(killmailHash: "e24153813cdd602767d8c57cc9177db0529b49e2", killmailID: 17177435),
						  ESI.Killmails.Recent(killmailHash: "318934af09c6b69eaf1559add1817af4a09db539", killmailID: 17146086),
						  ESI.Killmails.Recent(killmailHash: "34dea32e3a10119653d398f35d3f13b974980b6f", killmailID: 17146079),
						  ESI.Killmails.Recent(killmailHash: "a3d8ba67ab493e0439621e8450c1f58a64043189", killmailID: 16962950),
						  ESI.Killmails.Recent(killmailHash: "6a40f778a7850e49098846604195c59ad334bccd", killmailID: 15449858),
						  ESI.Killmails.Recent(killmailHash: "bdefead924c961b30ea03346f54442b3abece1f7", killmailID: 15417173),
						  ESI.Killmails.Recent(killmailHash: "c24704b8676a61b9779ff76cb7c0281e2af1ae67", killmailID: 15318134),
						  ESI.Killmails.Recent(killmailHash: "3c75c03a38c7413861fce7e8f15b033a01674975", killmailID: 15315140),
						  ESI.Killmails.Recent(killmailHash: "bda2cf4e57555cd294fd4b1abfa4f2f03ced9ee8", killmailID: 15272883),
						  ESI.Killmails.Recent(killmailHash: "12fd738f83ca34bb878f316ea1fed627cc05c44c", killmailID: 15261558),
							ESI.Killmails.Recent(killmailHash: "d933e2baa7ec13f55f9f2907739c38593728ebd4", killmailID: 15149922)],
						 [ESI.Killmails.Recent(killmailHash: "6f3a3c2e89a91a1276828de58d3f3c5b7cb316ef", killmailID: 15138881),
						  ESI.Killmails.Recent(killmailHash: "328f98d008ad866a2b2d2d7aac74c84ec25b0672", killmailID: 15138868),
						  ESI.Killmails.Recent(killmailHash: "2879725bf50c18ee456008b0d87534c13e104081", killmailID: 14995414),
						  ESI.Killmails.Recent(killmailHash: "62c39aee3fd3823154ad7d690e85ea11726f1800", killmailID: 14933564),
						  ESI.Killmails.Recent(killmailHash: "11bf50e9c553b3ef17758efaeced924337d8ddfa", killmailID: 14933555),
						  ESI.Killmails.Recent(killmailHash: "a53db2e6eddd38063068f39990b1bd0debb861d7", killmailID: 14887581),
						  ESI.Killmails.Recent(killmailHash: "406076c479ae2f99fb1054dc975cdb87804ca00c", killmailID: 14577895),
						  ESI.Killmails.Recent(killmailHash: "2434b5400b8881819e19f3f25691879d1461a8da", killmailID: 14379843),
						  ESI.Killmails.Recent(killmailHash: "a07b6f7927a057df86ebdf16f65253cfb06f3043", killmailID: 14379829),
						  ESI.Killmails.Recent(killmailHash: "fa03bb508ed171a9791134103327ce4047b33460", killmailID: 14379819),
						  ESI.Killmails.Recent(killmailHash: "2bbda385c959a3aabfbbab7a63bc69d2ba1e8d1d", killmailID: 14379807),
						  ESI.Killmails.Recent(killmailHash: "78adb51cce39e2bed7ce471b9515c0d9334f740f", killmailID: 14379161),
						  ESI.Killmails.Recent(killmailHash: "43b0562b8ec6a28aa0c6bc0f3b84f149519218f6", killmailID: 14176265),
						  ESI.Killmails.Recent(killmailHash: "0ee261c10780ed23b393f578201b885c1b0f5c90", killmailID: 14176247),
						  ESI.Killmails.Recent(killmailHash: "3bf94daf279d159cfdd91a1e775745edba2ff4c9", killmailID: 14077407),
						  ESI.Killmails.Recent(killmailHash: "5fc4ff38c2adf2569180a1fb064b27ff12995d52", killmailID: 13880842),
						  ESI.Killmails.Recent(killmailHash: "52fcd179da689d9096e4e68f5eaf6116407b77d7", killmailID: 13407928),
						  ESI.Killmails.Recent(killmailHash: "d3a325d227e801a87ff24ffbbdec7fce06accaab", killmailID: 13332045),
						  ESI.Killmails.Recent(killmailHash: "270c842cb6f7de0b8f1c5bf6cff545c350fb4e5f", killmailID: 13297664),
							ESI.Killmails.Recent(killmailHash: "559a226865863fc99ba4964a0ae3d249afd9a1fe", killmailID: 12429912)],
						 [ESI.Killmails.Recent(killmailHash: "0b56cfce9255eae6623fd0f3f17af36db4e3f8bc", killmailID: 12363310),
						  ESI.Killmails.Recent(killmailHash: "1a6e4dba56259753b932d457ee4bc34a0a292571", killmailID: 11587535)]]
		return .init(ESI.Result(value: killmails[(page ?? 1) - 1], expires: .distantFuture, metadata: ["x-pages" : "\(killmails.count)"]))*/
	}
	
	func killmailInfo(killmailHash: String, killmailID: Int64, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<ESI.Killmails.Killmail>> {
		return esi.killmails.getSingleKillmail(killmailHash: killmailHash, killmailID: Int(killmailID), cachePolicy: cachePolicy)
	}
	
	func zKillmails(filter: [EVEAPI.ZKillboard.Filter], page: Int?, cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<[EVEAPI.ZKillboard.Killmail]>> {
		return zKillboard.kills(filter: filter, page: page, cachePolicy: cachePolicy)
	}
}
