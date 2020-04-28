//
//  FittingProject.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/23/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp
import Combine
import SwiftUI
import CoreData
import Expressible
import EVEAPI

class FittingAutosaver: ObservableObject {
    let project: FittingProject
    
    init(project: FittingProject) {
        self.project = project
    }
    
    deinit {
        let project = self.project
        if project.hasChanges {
            project.managedObjectContext.perform {
                project.save()
            }
        }
    }
}

class FittingProject: Codable, ObservableObject, Identifiable, Hashable {
    static let managedObjectContextKey = CodingUserInfoKey(rawValue: "managedObjectContext")!
    
    var gang: DGMGang?
    var structure: DGMStructure?

    private var gangSubscription: AnyCancellable?
    private var structureSubscription: AnyCancellable?
    
    private(set) var hasChanges = false
    
    var loadouts: [DGMShip: Loadout] = [:]
    var fleet: Fleet?
    let managedObjectContext: NSManagedObjectContext
    
    enum CodingKeys: String, CodingKey {
        case gang
        case loadouts
        case fleet
        case structure
    }
    
    required init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[FittingProject.managedObjectContextKey] as? NSManagedObjectContext else {throw RuntimeError.missingCodingUserInfoKey(FittingProject.managedObjectContextKey)}
        managedObjectContext = context
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gang = try container.decodeIfPresent(DGMGang.self, forKey: .gang)
        structure = try container.decodeIfPresent(DGMStructure.self, forKey: .structure)
        if let fleetURL = try container.decodeIfPresent(URL.self, forKey: .fleet) {
            fleet = managedObjectContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: fleetURL).flatMap{try? managedObjectContext.existingObject(with: $0) as? Fleet}
        }
        let loadoutURLs = try container.decode([Int: URL].self, forKey: .loadouts)
        let ships = Dictionary(gang?.pilots.compactMap{$0.ship}.map{($0.identifier, $0)} ?? []) {a, _ in a}
        loadouts = [:]
        for (id, url) in loadoutURLs {
            guard let ship = ships[id] else {continue}
            guard let loadout = managedObjectContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url).flatMap({try? managedObjectContext.existingObject(with: $0) as? Loadout}) else {continue}
            loadouts[ship] = loadout
        }
        
        gangSubscription = gang?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
        structureSubscription = structure?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(gang, forKey: .gang)
        try container.encodeIfPresent(structure, forKey: .structure)

        let loadouts = Dictionary(self.loadouts.map { ($0.key.identifier, $0.value.objectID.uriRepresentation()) }) {a, _ in a}
        try container.encode(loadouts, forKey: .loadouts)

        try container.encodeIfPresent(fleet?.objectID.uriRepresentation(), forKey: .fleet)

    }
    
    init(ship: DGMTypeID, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        self.managedObjectContext = managedObjectContext
        try add(ship: ship, skillLevels: skillLevels)
        
        gangSubscription = gang?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
        structureSubscription = structure?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
    }
    
    @discardableResult
    func add(ship: DGMTypeID, skillLevels: DGMSkillLevels) throws -> DGMShip {
        if let structure = try? DGMStructure(typeID: ship) {
            self.structure = structure
            return structure
        }
        else {
            let pilot = try DGMCharacter()
            pilot.setSkillLevels(skillLevels)
            if gang == nil {
                gang = try DGMGang()
            }
            gang?.add(pilot)
            pilot.ship = try DGMShip(typeID: ship)
            return pilot.ship!
        }
    }
    
    init(loadout: Loadout, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        self.managedObjectContext = managedObjectContext
        try add(loadout: loadout, skillLevels: skillLevels)
        gangSubscription = gang?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
        structureSubscription = structure?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
    }
    
    @discardableResult
    func add(loadout: Loadout, skillLevels: DGMSkillLevels) throws -> DGMShip {
        let ship = try add(ship: DGMTypeID(loadout.typeID), skillLevels: skillLevels)
        
        ship.name = loadout.name ?? ""
        if let loadout = loadout.ship {
            if let pilot = ship.parent as? DGMCharacter {
                pilot.loadout = loadout
            }
            else {
                ship.loadout = loadout
            }
        }
        loadouts[ship] = loadout
        return ship
    }
    
    init(killmail: ESI.Killmail, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        self.managedObjectContext = managedObjectContext
        try add(killmail: killmail, skillLevels: skillLevels)
        gangSubscription = gang?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
        structureSubscription = structure?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
    }
    
    @discardableResult
    func add(killmail: ESI.Killmail, skillLevels: DGMSkillLevels) throws -> DGMShip {
        let items = killmail.victim.items?.map {
            (typeID: DGMTypeID($0.itemTypeID), quantity: ($0.quantityDropped ?? 0) + ($0.quantityDestroyed ?? 0), flag: ESI.LocationFlag(rawValue: $0.flag) ?? .cargo)
        }
        
        return try add(ship: DGMTypeID(killmail.victim.shipTypeID), items: items ?? [], skillLevels: skillLevels)
    }
    
    @discardableResult
    func add<Flag: FittingFlag>(ship: DGMTypeID, items: [(typeID: DGMTypeID, quantity: Int64, flag: Flag)], skillLevels: DGMSkillLevels) throws -> DGMShip {
        let ship = try add(ship: ship, skillLevels: skillLevels)
        
        var cargo = Set<DGMTypeID>()
        var requiresAmmo = [DGMModule]()
        
        for item in items {
            if item.flag.isDrone {
                for _ in 0..<item.quantity {
                    try ship.add(DGMDrone(typeID: item.typeID))
                }
            }
            else if item.flag.isCargo {
                cargo.insert(item.typeID)
            }
            else {
                do {
                    for _ in 0..<max(item.quantity, 1) {
                        let module = try DGMModule(typeID: item.typeID)
                        try ship.add(module, ignoringRequirements: true)
                        if (!module.chargeGroups.isEmpty) {
                            requiresAmmo.append(module)
                        }
                    }
                }
                catch {
                    cargo.insert(item.typeID)
                }
            }
        }
        
        for module in requiresAmmo {
            for typeID in cargo {
                do {
                    try module.setCharge(DGMCharge(typeID: typeID))
                    break
                }
                catch {
                }
            }
        }
        return ship
    }
    
    init(asset: AssetsData.Asset, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        self.managedObjectContext = managedObjectContext
        try add(asset: asset, skillLevels: skillLevels)
        gangSubscription = gang?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
        structureSubscription = structure?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
    }
    
    @discardableResult
    func add(asset: AssetsData.Asset, skillLevels: DGMSkillLevels) throws -> DGMShip {
        let items = asset.nested.map {
            (typeID: DGMTypeID($0.underlyingAsset.typeID), quantity: Int64($0.underlyingAsset.quantity), flag: $0.underlyingAsset.locationFlag)
        }
        
        return try add(ship: DGMTypeID(asset.underlyingAsset.typeID), items: items, skillLevels: skillLevels)
    }
    
    init(fitting: ESI.Fittings.Element, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        self.managedObjectContext = managedObjectContext
        try add(fitting: fitting, skillLevels: skillLevels)
        gangSubscription = gang?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
        structureSubscription = structure?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
    }
    
    @discardableResult
    func add(fitting: ESI.Fittings.Element, skillLevels: DGMSkillLevels) throws -> DGMShip {
        let items = fitting.items.map {
            (typeID: DGMTypeID($0.typeID), quantity: Int64($0.quantity), flag: $0.flag)
        }
        
        return try add(ship: DGMTypeID(fitting.shipTypeID), items: items, skillLevels: skillLevels)
    }
    
    init(gang: DGMGang, managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.gang = gang
        self.loadouts = [:]
        gangSubscription = gang.objectWillChange.sink { [weak self] in self?.hasChanges = true }
    }
    
    init(fleet: Fleet, configuration: FleetConfiguration, skillLevels: [URL: DGMSkillLevels], managedObjectContext: NSManagedObjectContext) throws {
        self.managedObjectContext = managedObjectContext
        try (fleet.loadouts?.allObjects as? [Loadout])?.forEach {
            let pilot = try add(loadout: $0, skillLevels: .level(5)).parent as? DGMCharacter
            if let url = pilot?.url, let skills = skillLevels[url] {
                pilot?.setSkillLevels(skills)
            }
        }
        gang?.fleetConfiguration = configuration
        self.fleet = fleet
        gangSubscription = gang?.objectWillChange.sink { [weak self] in self?.hasChanges = true }
    }
    
    func save() {
        let pilots = gang?.pilots ?? []
        pilots.forEach { pilot in
            guard let ship = pilot.ship else {return}
            
            
            let loadout: Loadout? = loadouts[ship] ?? {
                let isEmpty = ship.modules.isEmpty && ship.drones.isEmpty && pilots.count == 1
                
                if !isEmpty {
                    let loadout = Loadout(context: managedObjectContext)
                    loadout.data = LoadoutData(context: managedObjectContext)
                    loadout.typeID = Int32(ship.typeID)
                    loadout.uuid = UUID().uuidString
                    loadouts[ship] = loadout
                    return loadout
                }
                else {
                    return nil
                }
            }()
            if let loadout = loadout {
                loadout.name = ship.name
                if loadout.data == nil {
                    loadout.data = LoadoutData(context: managedObjectContext)
                }
                loadout.ship = pilot.loadout
            }
        }
        
        if pilots.count > 1 {
            if fleet == nil {
                fleet = Fleet(context: managedObjectContext)
            }
            fleet?.configuration = gang.flatMap{try? JSONEncoder().encode($0.fleetConfiguration)}
            let fleetLoadouts = Set(fleet?.loadouts?.allObjects as? [Loadout] ?? [])
            fleetLoadouts.subtracting(loadouts.values).forEach {
                fleet?.removeFromLoadouts($0)
            }
            Set(loadouts.values).subtracting(fleetLoadouts).forEach {
                fleet?.addToLoadouts($0)
            }
            fleet?.name = pilots.compactMap{$0.ship}.compactMap{$0.type(from: managedObjectContext)?.typeName}.joined(separator: ", ")
            
        }
        else {
            if let fleet = self.fleet {
                managedObjectContext.delete(fleet)
            }
        }
        
        if let structure = self.structure {
            let loadout: Loadout? = loadouts[structure] ?? {
                let isEmpty = structure.modules.isEmpty && structure.drones.isEmpty
                
                if !isEmpty {
                    let loadout = Loadout(context: managedObjectContext)
                    loadout.data = LoadoutData(context: managedObjectContext)
                    loadout.typeID = Int32(structure.typeID)
                    loadout.uuid = UUID().uuidString
                    loadouts[structure] = loadout
                    return loadout
                }
                else {
                    return nil
                }
            }()
            if let loadout = loadout {
                loadout.name = structure.name
                if loadout.data == nil {
                    loadout.data = LoadoutData(context: managedObjectContext)
                }
                loadout.ship = structure.loadout
            }
        }
        
        if managedObjectContext.hasChanges {
            try? managedObjectContext.save()
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FittingProject, rhs: FittingProject) -> Bool {
        lhs === rhs
    }

}

extension FittingProject: UserActivityProvider {
    func userActivity() -> NSUserActivity? {
        try? NSUserActivity(fitting: self)
    }
}
