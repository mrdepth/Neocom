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

extension DGMCharacter {
	class func url(account: Account) -> URL? {
		guard let uuid = account.uuid else {return nil}
		var components = URLComponents()
        components.scheme = URLScheme.neocom
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
		components.scheme = URLScheme.neocom
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
		components.scheme = URLScheme.neocom
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
    var loadout: Ship {
        get {

            var dronesDic = [Ship.Drone: Int]()
            
            for drone in self.drones {
                let key = Ship.Drone(typeID: drone.typeID, count: 0, id: drone.identifier, isActive: drone.isActive, isKamikaze: drone.isKamikaze, squadronTag: drone.squadronTag)
                dronesDic[key, default: 0] += 1
            }
            
            var modules = [DGMModule.Slot: [Ship.Module]]()
            
            for module in self.modules {
                modules[module.slot, default: []].append(Ship.Module(typeID: module.typeID,
                                                                     count: 1,
                                                                     id: module.identifier,
                                                                     state: module.state,
                                                                     charge: module.charge.map{Ship.Item(typeID: $0.typeID, count: module.charges)},
                                                                     socket: module.socket))
            }
            
            let drones = dronesDic.map{ (key, value) -> Ship.Drone in
                var drone = key
                drone.count = value
                return drone
            }
            let cargo = self.cargo.map {
                Ship.Item(typeID: $0.typeID, count: $0.quantity)
            }
            
            return Ship(typeID: typeID,
                        name: name.isEmpty ? nil : name,
                        modules: modules,
                        drones: drones,
                        cargo: cargo,
                        implants: nil,
                        boosters: nil)
        }
        set {
            name = newValue.name ?? ""
            var ids = IndexSet(integersIn: 1..<Int.max)

            for drone in newValue.drones ?? [] {
                do {
                    let identifier = drone.id ?? ids.first ?? 0
                    ids.remove(identifier)
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
                        let identifier = module.id ?? ids.first ?? 0
                        ids.remove(identifier)
                        
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
            newValue.cargo?.forEach {
                do {
                    let cargo = try DGMCargo(typeID: $0.typeID)
                    cargo.quantity = $0.count
                    try add(cargo)
                }
                catch {
                    
                }
            }
        }
    }
}

extension DGMCharacter {
    var loadout: Ship {
        get {
            var loadout = self.ship?.loadout ?? Ship(typeID: 0, name: "", modules: nil, drones: nil, cargo: nil, implants: nil, boosters: nil)
            loadout.implants = implants.map{ $0.typeID }
            loadout.boosters = boosters.map{ $0.typeID }
            return loadout
        }
        set {
            newValue.implants?.forEach {try? add(DGMImplant(typeID: $0))}
            newValue.boosters?.forEach {try? add(DGMBooster(typeID: $0))}
            if ship == nil {
                ship = try? DGMShip(typeID: newValue.typeID)
                ship?.name = newValue.name ?? ""
            }
            ship?.loadout = newValue
        }
    }
}

extension DGMGang {
    var fleetConfiguration: FleetConfiguration {
        get {
            let pilots = self.pilots
            
            let pilotsLevels = Dictionary(pilots.map{($0.identifier, $0.url?.absoluteString ?? DGMCharacter.url(level: 5).absoluteString)}) {a, _ in a}
            
            
            var links = [Int: Int]()
            for pilot in pilots {
                for module in pilot.ship?.modules ?? [] {
                    if let target = module.target?.parent {
                        links[module.identifier] = target.identifier
                    }
                }
                for drone in pilot.ship?.drones ?? [] {
                    if let target = drone.target?.parent {
                        links[drone.identifier] = target.identifier
                    }
                }
            }
            return FleetConfiguration(pilots: pilotsLevels, links: links)
        }
        set {
            let pilots = self.pilots
            
            let pilotsMap = Dictionary(pilots.map{($0.identifier, $0)}) {a, _ in a}
            
            for pilot in pilots {
                for module in pilot.ship?.modules ?? [] {
                    guard let link = newValue.links[module.identifier] else {continue}
                    module.target = pilotsMap[link]?.ship
                }
                for drone in pilot.ship?.drones ?? [] {
                    guard let link = newValue.links[drone.identifier] else {continue}
                    drone.target = pilotsMap[link]?.ship
                }
            }
        }
    }
}

extension DGMPlanet {
    convenience init(planet: ESI.Planets.Element, info: ESI.PlanetInfo) throws {
        self.init()
        for pin in info.pins {
            guard self[pin.pinID] == nil else {throw RuntimeError.invalidPlanetLayout}
            let facility = try add(facility: DGMTypeID(pin.typeID), identifier: pin.pinID)
            
            switch facility {
            case let ecu as DGMExtractorControlUnit:
                ecu.launchTime = pin.lastCycleStart ?? Date(timeIntervalSinceReferenceDate: 0)
                ecu.installTime = pin.installTime ?? Date(timeIntervalSinceReferenceDate: 0)
                ecu.expiryTime = pin.expiryTime ?? Date(timeIntervalSinceReferenceDate: 0)
                ecu.cycleTime = TimeInterval(pin.extractorDetails?.cycleTime ?? 0)
                ecu.quantityPerCycle = pin.extractorDetails?.qtyPerCycle ?? 0
//                ecu.quantityPerCycle *= 10
            case let factory as DGMFactory:
                factory.launchTime = pin.lastCycleStart ?? Date(timeIntervalSinceReferenceDate: 0)
                if let schematicID = pin.schematicID {
                    factory.schematicID = schematicID
                }
            default:
                break
            }
            pin.contents?.filter {$0.amount > 0}.forEach {
                try? facility.add(DGMCommodity(typeID: $0.typeID, quantity: Int($0.amount)))
            }
        }
        
        for route in info.routes {
            guard let source = self[route.sourcePinID], let destination = self[route.destinationPinID] else {throw RuntimeError.invalidPlanetLayout}
            let route = try DGMRoute(from: source, to: destination, commodity: DGMCommodity(typeID: route.contentTypeID, quantity: Int(route.quantity)))
            add(route: route)
        }

        lastUpdate = planet.lastUpdate
    }
}

extension DGMFacility {
    var sortDescriptor: (Int, String) {
        if self is DGMExtractorControlUnit {
            return (0, name)
        }
        else if self is DGMStorage {
            return (1, name)
        }
        else if self is DGMFactory {
            return (2, name)
        }
        else {
            return (3, name)
        }
    }
}

extension DGMDrone.Squadron {
    var title: String {
        switch self {
        case .heavy, .standupHeavy:
            return NSLocalizedString("Heavy", comment: "")
        case .light, .standupLight:
            return NSLocalizedString("Light", comment: "")
        case .support, .standupSupport:
            return NSLocalizedString("Support", comment: "")
        case .none:
            return NSLocalizedString("Drone", comment: "")
        }
    }
}
