//
//  NCLoadout.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingLoadoutItem: NSObject, NSCoding {
	let typeID: Int
	var count: Int
	let identifier: String?
	
	init(item: NCFittingItem, count: Int = 1) {
		self.typeID = item.typeID
		self.count = count
		self.identifier = item.identifier
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		typeID = aDecoder.decodeInteger(forKey: "typeID")
		count = aDecoder.containsValue(forKey: "count") ? aDecoder.decodeInteger(forKey: "count") : 1
		identifier = (aDecoder.decodeObject(forKey: "identifier") as? String)
		super.init()
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(typeID, forKey: "typeID")
		if count != 1 {
			aCoder.encode(count, forKey: "count")
		}
		aCoder.encode(identifier, forKey: "identifier")
	}
	
	public static func ==(lhs: NCFittingLoadoutItem, rhs: NCFittingLoadoutItem) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
	
	override var hashValue: Int {
		return [typeID, count].hashValue
	}
}

class NCFittingLoadoutModule: NCFittingLoadoutItem {
	let state: NCFittingModuleState
	let charge: NCFittingLoadoutItem?
	let socket: Int
	
	init(module: NCFittingModule) {
		state = module.preferredState
		if let charge = module.charge {
			self.charge = NCFittingLoadoutItem(item: charge)
		}
		else {
			self.charge = nil
		}
		socket = module.socket
		super.init(item: module)
	}
	
	required init?(coder aDecoder: NSCoder) {
		state = NCFittingModuleState(rawValue: aDecoder.decodeInteger(forKey: "state")) ?? .unknown
		charge = aDecoder.decodeObject(forKey: "charge") as? NCFittingLoadoutItem
		socket = aDecoder.containsValue(forKey: "socket") ? aDecoder.decodeInteger(forKey: "socket") : -1
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(state.rawValue, forKey: "state")
		aCoder.encode(charge, forKey: "charge")
		aCoder.encode(socket, forKey: "socket")
	}

	override var hashValue: Int {
		return [typeID, count, state.rawValue, charge?.typeID ?? 0].hashValue
	}
}

class NCFittingLoadoutDrone: NCFittingLoadoutItem {
	let isActive: Bool
	let squadronTag: Int
	
	init(drone: NCFittingDrone) {
		self.isActive = drone.isActive
		self.squadronTag = drone.squadronTag
		super.init(item: drone)
	}

	required init?(coder aDecoder: NSCoder) {
		isActive = aDecoder.containsValue(forKey: "isActive") ? aDecoder.decodeBool(forKey: "isActive") : true
		squadronTag = aDecoder.containsValue(forKey: "squadronTag") ? aDecoder.decodeInteger(forKey: "squadronTag") : -1
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		if !isActive {
			aCoder.encode(isActive, forKey: "isActive")
		}
		aCoder.encode(squadronTag, forKey: "squadronTag")
	}

	override var hashValue: Int {
		return [typeID, count, isActive ? 1 : 0].hashValue
	}
}


public class NCFittingLoadout: NSObject, NSCoding {
	var modules: [NCFittingModuleSlot: [NCFittingLoadoutModule]]?
	var drones: [NCFittingLoadoutDrone]?
	var cargo: [NCFittingLoadoutItem]?
	var implants: [NCFittingLoadoutItem]?
	var boosters: [NCFittingLoadoutItem]?
	
	override init() {
		super.init()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		modules = [NCFittingModuleSlot: [NCFittingLoadoutModule]]()
		for (key, value) in aDecoder.decodeObject(forKey: "modules") as? [Int: [NCFittingLoadoutModule]] ?? [:] {
			guard let key = NCFittingModuleSlot(rawValue: key) else {continue}
			modules?[key] = value
		}
		
		drones = aDecoder.decodeObject(forKey: "drones") as? [NCFittingLoadoutDrone]
		cargo = aDecoder.decodeObject(forKey: "cargo") as? [NCFittingLoadoutItem]
		implants = aDecoder.decodeObject(forKey: "implants") as? [NCFittingLoadoutItem]
		boosters = aDecoder.decodeObject(forKey: "boosters") as? [NCFittingLoadoutItem]
		super.init()
	}
	
	public func encode(with aCoder: NSCoder) {
		var dic = [Int: [NCFittingLoadoutModule]]()
		for (key, value) in modules ?? [:] {
			dic[key.rawValue] = value
		}
		
		aCoder.encode(dic, forKey:"modules")

		if drones?.count ?? 0 > 0 {
			aCoder.encode(drones, forKey: "drones")
		}
		if cargo?.count ?? 0 > 0 {
			aCoder.encode(cargo, forKey: "cargo")
		}
		if implants?.count ?? 0 > 0 {
			aCoder.encode(implants, forKey: "implants")
		}
		if boosters?.count ?? 0 > 0 {
			aCoder.encode(boosters, forKey: "boosters")
		}
	}
}


extension NCFittingModuleSlot {
	var image: UIImage? {
		switch self {
		case .hi:
			return #imageLiteral(resourceName: "slotHigh")
		case .med:
			return #imageLiteral(resourceName: "slotMed")
		case .low:
			return #imageLiteral(resourceName: "slotLow")
		case .rig:
			return #imageLiteral(resourceName: "slotRig")
		case .subsystem:
			return #imageLiteral(resourceName: "slotSubsystem")
		case .service:
			return #imageLiteral(resourceName: "slotService")
		case .mode:
			return #imageLiteral(resourceName: "slotSubsystem")
		default:
			return nil
		}
	}
	
	var title: String? {
		switch self {
		case .hi:
			return NSLocalizedString("Hi Slot", comment: "")
		case .med:
			return NSLocalizedString("Med Slot", comment: "")
		case .low:
			return NSLocalizedString("Low Slot", comment: "")
		case .rig:
			return NSLocalizedString("Rig Slot", comment: "")
		case .subsystem:
			return NSLocalizedString("Subsystem Slot", comment: "")
		case .service:
			return NSLocalizedString("Services", comment: "")
		case .mode:
			return NSLocalizedString("Tactical Mode", comment: "")
		default:
			return nil
		}
	}
}

extension NCFittingModuleState {
	var image: UIImage? {
		switch self {
		case .offline:
			return #imageLiteral(resourceName: "offline")
		case .online:
			return #imageLiteral(resourceName: "online")
		case .active:
			return #imageLiteral(resourceName: "active")
		case .overloaded:
			return #imageLiteral(resourceName: "overheated")
		default:
			return nil
		}
	}
	
	var title: String? {
		switch self {
		case .offline:
			return NSLocalizedString("Offline", comment: "")
		case .online:
			return NSLocalizedString("Online", comment: "")
		case .active:
			return NSLocalizedString("Active", comment: "")
		case .overloaded:
			return NSLocalizedString("Overheated", comment: "")
		default:
			return nil
		}
	}
}

extension NCFittingScanType {
	var image: UIImage? {
		switch self {
		case .gravimetric:
			return #imageLiteral(resourceName: "gravimetric")
		case .magnetometric:
			return #imageLiteral(resourceName: "magnetometric")
		case .ladar:
			return #imageLiteral(resourceName: "ladar")
		case .radar:
			return #imageLiteral(resourceName: "radar")
		case .multispectral:
			return #imageLiteral(resourceName: "multispectral")
		}
	}
	
	var title: String? {
		switch self {
		case .gravimetric:
			return NSLocalizedString("Gravimetric", comment: "")
		case .magnetometric:
			return NSLocalizedString("Magnetometric", comment: "")
		case .ladar:
			return NSLocalizedString("Ladar", comment: "")
		case .radar:
			return NSLocalizedString("Radar", comment: "")
		case .multispectral:
			return NSLocalizedString("Multispectral", comment: "")
		}
	}
}

extension NCFittingDamage {
	static let omni = NCFittingDamage(em: 0.25, thermal: 0.25, kinetic: 0.25, explosive: 0.25)
	var total: Double {
		return em + kinetic + thermal + explosive
	}
	static func + (lhs: NCFittingDamage, rhs: NCFittingDamage) -> NCFittingDamage {
		return NCFittingDamage(em: lhs.em + rhs.em, thermal: lhs.thermal + rhs.thermal, kinetic: lhs.kinetic + rhs.kinetic, explosive: lhs.explosive + rhs.explosive)
	}
}

extension NCFittingFighterSquadron {
	var title: String? {
		switch self {
		case .heavy:
			return NSLocalizedString("Heavy", comment: "")
		case .light:
			return NSLocalizedString("Light", comment: "")
		case .support:
			return NSLocalizedString("Support", comment: "")
		case .none:
			return NSLocalizedString("Drone", comment: "")
		}
	}
}

extension NCFittingAccuracy {
	var color: UIColor {
		switch self {
		case .none:
			return .white
		case .low:
			return .red
		case .average:
			return .yellow
		case .good:
			return .green
		}
	}
}

extension NCFittingSkills{
	func set(levels: [Int: Int]) {
		__setLevels(levels as [NSNumber: NSNumber])
	}
}

extension NCFittingDamage: Hashable {
	public var hashValue: Int {
		return [em, kinetic, thermal, explosive].hashValue
	}
	
	public static func == (lhs: NCFittingDamage, rhs: NCFittingDamage) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}

extension NCFittingItem {
	var identifier: String? {
		get {
			return engine?.identifier(for: self)
		}
		set {
			engine?.assign(identifier: newValue, for: self)
		}
	}
}

extension NCFittingCharacter {
	
	var loadout: NCFittingLoadout {
		get {
			let loadout = NCFittingLoadout()
			loadout.implants = implants.all.map({NCFittingLoadoutItem(item: $0)})
			loadout.boosters = boosters.all.map({NCFittingLoadoutItem(item: $0)})
			
			var drones = [String: NCFittingLoadoutDrone]()
			for drone in ship?.drones ?? [] {
				let identifier = drone.identifier ?? "\([drone.typeID, drone.isActive, drone.squadronTag].hashValue)"
				
				if (drones[identifier]?.count += 1) == nil {
					drones[identifier] = NCFittingLoadoutDrone(drone: drone)
				}
			}
			
			loadout.drones = Array(drones.values)
			
			var modules = [NCFittingModuleSlot: [NCFittingLoadoutModule]]()
			
			for module in ship?.modules ?? [] {
				guard !module.isDummy else {continue}
				var array = modules[module.slot] ?? []
				array.append(NCFittingLoadoutModule(module: module))
				modules[module.slot] = array
			}
			
			loadout.modules = modules
			
			return loadout
		}
		set {
			let ship = self.ship!
			for implant in newValue.implants ?? [] {
				addImplant(typeID: implant.typeID)
			}
			for booster in newValue.boosters ?? [] {
				addBooster(typeID: booster.typeID)
			}
			for drone in newValue.drones ?? [] {
				let identifier = drone.identifier ?? UUID().uuidString
				for _ in 0..<drone.count {
					guard let item = ship.addDrone(typeID: drone.typeID, squadronTag: drone.squadronTag) else {break}
					item.isActive = drone.isActive
					item.identifier = identifier
				}
			}
			for (_, modules) in newValue.modules?.sorted(by: { $0.key.rawValue > $1.key.rawValue }) ?? [] {
				for module in modules {
					let identifier = module.identifier ?? UUID().uuidString
					for _ in 0..<module.count {
						guard let m = ship.addModule(typeID: module.typeID, socket: module.socket) else {break}
						m.identifier = identifier
						m.preferredState = module.state
						if let charge = module.charge {
							m.charge = NCFittingCharge(typeID: charge.typeID)
						}
					}
				}
			}
		}
	}
	
	@nonobjc class func url(account: NCAccount) -> URL? {
		guard let uuid = account.uuid else {return nil}
		var components = URLComponents()
		components.scheme = NCURLScheme
		components.host = "character"
		
		var queryItems = [URLQueryItem(name: "accountUUID", value: uuid)]
		
		if let name = account.characterName {
			queryItems.append(URLQueryItem(name: "name", value: name))
		}
		queryItems.append(URLQueryItem(name: "characterID", value: "\(account.characterID)"))
		
		components.queryItems = queryItems
		return components.url!
	}

	@nonobjc class func url(level: Int) -> URL {
		var components = URLComponents()
		components.scheme = NCURLScheme
		components.host = "character"
		components.queryItems = [
			URLQueryItem(name: "level", value: String(level)),
			URLQueryItem(name: "name", value: NSLocalizedString("All Skills", comment: "") + " " + String(romanNumber: level))
		]
		return components.url!
	}

	@nonobjc class func url(character: NCFitCharacter) -> URL? {
		guard let uuid = character.uuid else {return nil}
		var components = URLComponents()
		components.scheme = NCURLScheme
		components.host = "character"
		components.queryItems = [
			URLQueryItem(name: "characterUUID", value: uuid),
			URLQueryItem(name: "name", value: character.name ?? "")
		]
		return components.url!
	}

	var url: URL? {
		return URL(string: characterName)
	}
	
	var account: NCAccount? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let accountUUID = components.queryItems?.first(where: {$0.name == "accountUUID"})?.value else {return nil}
		return NCStorage.sharedStorage?.accounts[accountUUID]
	}

	var fitCharacter: NCFitCharacter? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let characterUUID = components.queryItems?.first(where: {$0.name == "characterUUID"})?.value else {return nil}
		let character: NCFitCharacter? = NCStorage.sharedStorage?.viewContext.fetch("FitCharacter", where: "uuid == %@", characterUUID)
		return character
	}

	var level: Int? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let level = components.queryItems?.first(where: {$0.name == "level"})?.value else {return nil}
		return Int(level)
	}
	
	@nonobjc func setSkills(from url: URL, completionHandler: ((Bool) -> Void)? = nil) {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
			let queryItems = components.queryItems,
			components.scheme == NCURLScheme,
			components.host == "character" else {
			completionHandler?(false)
			return
		}

		if let item = queryItems.first(where: {$0.name == "accountUUID"}), let uuid = item.value {
			NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext in
				
				if let account = NCAccount.accounts(managedObjectContext: managedObjectContext)[uuid] {
					self.setSkills(from: account, completionHandler: completionHandler)
				}
				else {
					completionHandler?(false)
				}

			}
		}
		else if let item = queryItems.first(where: {$0.name == "characterUUID"}), let uuid = item.value {
			NCStorage.sharedStorage?.performTaskAndWait { managedObjectContext in
				
				if let character = NCFitCharacter.fitCharacters(managedObjectContext: managedObjectContext)[uuid] {
					self.setSkills(from: character, completionHandler: completionHandler)
				}
				else {
					completionHandler?(false)
				}
				
			}
		}
		else if let item = queryItems.first(where: {$0.name == "level"}), let level = Int(item.value ?? ""){
			setSkills(level: level, completionHandler: completionHandler)
		}
		else {
			completionHandler?(false)
		}
	}

	
	@nonobjc func setSkills(from account: NCAccount, completionHandler: ((Bool) -> Void)? = nil) {
		guard let engine = engine else {
			completionHandler?(false)
			return
		}
		
		let url = NCFittingCharacter.url(account: account)
		NCDataManager(account: account, cachePolicy: .returnCacheDataElseLoad).skills { result in
			switch result {
			case let .success(value, _):
				engine.perform {
					var levels = [Int: Int]()
					for skill in value.skills {
						levels[skill.skillID] = skill.currentSkillLevel
					}
					
					self.skills.set(levels: levels)
					self.characterName = url?.absoluteString ?? ""
					DispatchQueue.main.async {
						completionHandler?(true)
					}
				}

			default:
				DispatchQueue.main.async {
					completionHandler?(false)
				}
			}
		}
	}
	
	@nonobjc func setSkills(from character: NCFitCharacter, completionHandler: ((Bool) -> Void)? = nil) {
		guard let engine = engine else {
			completionHandler?(false)
			return
		}
		let url = NCFittingCharacter.url(character: character)
		let skills = character.skills ?? [:]
		engine.perform {
			self.skills.set(levels: skills)
			self.characterName = url?.absoluteString ?? ""
			DispatchQueue.main.async {
				completionHandler?(true)
			}
		}
	}

	
	@nonobjc func setSkills(level: Int, completionHandler: ((Bool) -> Void)? = nil) {
		guard let engine = engine else {
			completionHandler?(false)
			return
		}
		let url = NCFittingCharacter.url(level: level)
		engine.perform {
			self.skills.setAllSkillsLevel(level)
			self.characterName = url.absoluteString
			DispatchQueue.main.async {
				completionHandler?(true)
			}
		}
	}
}
