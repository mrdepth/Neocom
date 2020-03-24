//
//  Dgmpp+Extension.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import CoreData
import Expressible
import Combine
import EVEAPI
import Alamofire

extension DGMType {
    func type(from managedObjectContext: NSManagedObjectContext) -> SDEInvType? {
        try? managedObjectContext.from(SDEInvType.self)
            .filter(/\SDEInvType.typeID == Int32(self.typeID))
            .first()
    }
}


extension DGMModule.Slot {
    var image: Image? {
        switch self {
        case .hi:
            return Image("slotHigh")
        case .med:
            return Image("slotMed")
        case .low:
            return Image("slotLow")
        case .rig:
            return Image("slotRig")
        case .subsystem:
            return Image("slotSubsystem")
        case .service:
            return Image("slotService")
        case .mode:
            return Image("slotSubsystem")
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
            return NSLocalizedString("Service Slot", comment: "")
        case .mode:
            return NSLocalizedString("Tactical Mode", comment: "")
        default:
            return nil
        }
    }
    
    var name: String? {
        switch self {
        case .hi:
            return "Hi Slot"
        case .med:
            return "Med Slot"
        case .low:
            return "Low Slot"
        case .rig:
            return "Rig Slot"
        case .subsystem:
            return "Subsystem Slot"
        case .service:
            return "Service Slot"
        case .mode:
            return "Tactical Mode"
        default:
            return nil
        }
    }
    
    init?(name: String) {
        if name.range(of: "hi slot")?.lowerBound == name.startIndex {
            self = .hi
        }
        else if name.range(of: "med slot")?.lowerBound == name.startIndex {
            self = .med
        }
        else if name.range(of: "low slot")?.lowerBound == name.startIndex {
            self = .low
        }
        else if name.range(of: "rig slot")?.lowerBound == name.startIndex {
            self = .rig
        }
        else if name.range(of: "subsystem slot")?.lowerBound == name.startIndex {
            self = .subsystem
        }
        else if name.range(of: "service slot")?.lowerBound == name.startIndex {
            self = .service
        }
        else {
            return nil
        }
    }
}

extension DGMModule.State {
    var image: Image? {
        switch self {
        case .offline:
            return Image("offline")
        case .online:
            return Image("online")
        case .active:
            return Image("active")
        case .overloaded:
            return Image("overheated")
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

enum DGMAccuracy {
    case none
    case low
    case average
    case good
}

extension DGMAccuracy {
    var color: Color? {
        switch self {
        case .none:
            return nil
        case .low:
            return Color(.systemRed)
        case .average:
            return Color(.systemYellow)
        case .good:
            return Color(.systemGreen)
        }
    }
}

extension DGMModule {
    func accuracy(targetSignature: DGMMeter, hitChance: DGMPercent = 0.75) -> DGMAccuracy{
        guard let ship = parent as? DGMShip else {return .none}
        
        let optimal = self.optimal
        let falloff = self.falloff
        let angularVelocity = self.angularVelocity(targetSignature: targetSignature, hitChance: hitChance) * DGMSeconds(1)
        guard angularVelocity > 0 else {return .none}
        
        let v0 = ship.maxVelocityInOrbit(optimal) * DGMSeconds(1)
        let v1 = ship.maxVelocityInOrbit(optimal + falloff) * DGMSeconds(1)
        if angularVelocity * optimal > v0 {
            return .good
        }
        else if angularVelocity * (optimal + falloff) > v1 {
            return .average
        }
        else {
            return .low
        }
    }
}

#if DEBUG
extension DGMGang {
    static func testGang(_ pilots: Int = 1) -> DGMGang {
        let gang = try! DGMGang()
        for _ in 0..<pilots {
            gang.add(.testCharacter())
        }
        return gang
    }
}

extension DGMCharacter {
    static func testCharacter() -> DGMCharacter {
        let pilot = try! DGMCharacter()
        pilot.ship = .testDominix()
        try! pilot.add(DGMImplant(typeID: 10211))
        try! pilot.add(DGMBooster(typeID: 10151))
        
        return pilot
    }
}

extension DGMShip {
    static func testDominix() -> DGMShip {
        let dominix = try! DGMShip(typeID: 645)
        try! dominix.add(DGMModule(typeID: 3154))
        try! dominix.add(DGMModule(typeID: 405))
        try! dominix.add(DGMModule(typeID: 3154))
        
        for _ in 0..<5 {
            try! dominix.add(DGMDrone(typeID: 2446))
        }
        return dominix
    }
}

#endif


extension DGMCharacter {
	class func url(account: Account) -> URL? {
		guard let uuid = account.uuid else {return nil}
		var components = URLComponents()
		components.scheme = Config.current.urlScheme
		components.host = "character"
		
		var queryItems = [URLQueryItem(name: "accountUUID", value: uuid)]
		
		if let name = account.characterName {
			queryItems.append(URLQueryItem(name: "name", value: name))
		}
		queryItems.append(URLQueryItem(name: "characterID", value: "\(account.characterID)"))
		
		components.queryItems = queryItems
		return components.url!
	}
	
	class func url(level: Int) -> URL {
		var components = URLComponents()
		components.scheme = Config.current.urlScheme
		components.host = "character"
		components.queryItems = [
			URLQueryItem(name: "level", value: String(level)),
			URLQueryItem(name: "name", value: NSLocalizedString("All Skills", comment: "") + " " + String(roman: level))
		]
		return components.url!
	}
	
	class func url(character: FitCharacter) -> URL? {
		guard let uuid = character.uuid else {return nil}
		var components = URLComponents()
		components.scheme = Config.current.urlScheme
		components.host = "character"
		components.queryItems = [
			URLQueryItem(name: "characterUUID", value: uuid),
			URLQueryItem(name: "name", value: character.name ?? "")
		]
		return components.url!
	}
    
    class func account(from url: URL) -> NSFetchRequest<Account>? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
        guard let accountUUID = components.queryItems?.first(where: {$0.name == "accountUUID"})?.value else {return nil}
        let request = NSFetchRequest<Account>(entityName: "Account")
        request.predicate = (/\Account.uuid == accountUUID).predicate()
        request.fetchLimit = 1
        return request
    }
	
    class func fitCharacter(from url: URL) -> NSFetchRequest<FitCharacter>? {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let characterUUID = components.queryItems?.first(where: {$0.name == "characterUUID"})?.value else {return nil}
		let request = NSFetchRequest<FitCharacter>(entityName: "FitCharacter")
		request.predicate = (/\FitCharacter.uuid == characterUUID).predicate()
		request.fetchLimit = 1
		return request
	}
    
    class func level(from url: URL) -> Int? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
        guard let level = components.queryItems?.first(where: {$0.name == "level"})?.value else {return nil}
        return Int(level)
    }
	
	var url: URL? {
        get {
            return URL(string: name)
        }
        set {
            name = newValue?.absoluteString ?? ""
        }
	}
    
    func setSkillLevels(_ levels: DGMSkillLevels) {
        switch levels {
        case let .levelsMap(levels, url):
            setSkillLevels(levels)
            self.url = url
        case let .level(level):
            setSkillLevels(level)
            self.url = DGMCharacter.url(level: level)
        }
    }
}



extension DGMDamageVector {
    init(_ damage: SDEDgmppItemDamage) {
        self.init(em: DGMHP(damage.emAmount),
                  thermal: DGMHP(damage.thermalAmount),
                  kinetic: DGMHP(damage.kineticAmount),
                  explosive: DGMHP(damage.explosiveAmount))
    }
    
//    init(_ damage: DamagePattern) {
//        self.init(em: DGMHP(damage.em),
//                  thermal: DGMHP(damage.thermal),
//                  kinetic: DGMHP(damage.kinetic),
//                  explosive: DGMHP(damage.explosive))
//    }
}


extension DGMShip {
    var loadout: LoadoutDescription {
        get {
            let loadout = LoadoutDescription()
            
            var drones = [Int: LoadoutDescription.Item.Drone]()
            for drone in self.drones {
                let identifier = drone.identifier
                if let drone = drones[identifier] {
                    drone.count += 1
                }
                else {
                    drones[identifier] = LoadoutDescription.Item.Drone(drone: drone)
                }
            }
            
            loadout.drones = Array(drones.values)
            
            var modules = [DGMModule.Slot: [LoadoutDescription.Item.Module]]()
            
            for module in self.modules {
                modules[module.slot, default: []].append(LoadoutDescription.Item.Module(module: module))
            }
            
            loadout.modules = modules
            
            return loadout
        }
        set {
            for drone in newValue.drones ?? [] {
                do {
                    let identifier = drone.identifier ?? UUID().hashValue
                    for _ in 0..<drone.count {
                        let item = try DGMDrone(typeID: drone.typeID)
                        try add(item, squadronTag: drone.squadronTag)
                        item.isActive = drone.isActive
                        item.isKamikaze = drone.isKamikaze
                        item.identifier = identifier
                    }
                }
                catch {
                }
            }
            for (_, modules) in newValue.modules?.sorted(by: { $0.key.rawValue > $1.key.rawValue }) ?? [] {
                for module in modules {
                    do {
                        let identifier = module.identifier ?? UUID().hashValue
                        for _ in 0..<module.count {
                            let item = try DGMModule(typeID: module.typeID)
                            try add(item, socket: module.socket, ignoringRequirements: true)
                            item.identifier = identifier
                            item.state = module.state
                            if let charge = module.charge {
                                try item.setCharge(DGMCharge(typeID: charge.typeID))
                            }
                        }
                    }
                    catch {
                    }
                }
            }
        }
    }
}

extension DGMCharacter {
    var loadout: LoadoutDescription {
        get {
            let loadout = self.ship?.loadout ?? LoadoutDescription()
            loadout.implants = implants.map{ LoadoutDescription.Item(type: $0) }
            loadout.boosters = boosters.map{ LoadoutDescription.Item(type: $0) }
            return loadout
        }
        set {
            for implant in newValue.implants ?? [] {
                try? add(DGMImplant(typeID: implant.typeID))
            }
            for booster in newValue.boosters ?? [] {
                try? add(DGMBooster(typeID: booster.typeID))
            }
            ship?.loadout = newValue
        }
    }
}
