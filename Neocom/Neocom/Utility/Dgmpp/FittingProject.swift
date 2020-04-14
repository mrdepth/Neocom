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

class FittingProject: ObservableObject, Identifiable, Hashable {
    let gang: DGMGang
    var loadouts: [DGMShip: Loadout]
    var fleet: Fleet?
    var structure: DGMStructure?
    
    init() throws {
        gang = try DGMGang()
        loadouts = [:]
    }
    
    convenience init(ship: DGMTypeID, skillLevels: DGMSkillLevels) throws {
        try self.init()
        try add(ship: ship, skillLevels: skillLevels)
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
            gang.add(pilot)
            pilot.ship = try DGMShip(typeID: ship)
            return pilot.ship!
        }
    }
    
    convenience init(loadout: Loadout, skillLevels: DGMSkillLevels) throws {
        try self.init()
        try add(loadout: loadout, skillLevels: skillLevels)
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
    
    convenience init(killmail: ESI.Killmail, skillLevels: DGMSkillLevels) throws {
        try self.init()
        try add(killmail: killmail, skillLevels: skillLevels)
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
    
    convenience init(asset: AssetsData.Asset, skillLevels: DGMSkillLevels) throws {
        try self.init()
        try add(asset: asset, skillLevels: skillLevels)
    }
    
    @discardableResult
    func add(asset: AssetsData.Asset, skillLevels: DGMSkillLevels) throws -> DGMShip {
        let items = asset.nested.map {
            (typeID: DGMTypeID($0.underlyingAsset.typeID), quantity: Int64($0.underlyingAsset.quantity), flag: $0.underlyingAsset.locationFlag)
        }
        
        return try add(ship: DGMTypeID(asset.underlyingAsset.typeID), items: items, skillLevels: skillLevels)
    }
    
    convenience init(fitting: ESI.Fittings.Element, skillLevels: DGMSkillLevels) throws {
        try self.init()
        try add(fitting: fitting, skillLevels: skillLevels)
    }
    
    @discardableResult
    func add(fitting: ESI.Fittings.Element, skillLevels: DGMSkillLevels) throws -> DGMShip {
        let items = fitting.items.map {
            (typeID: DGMTypeID($0.typeID), quantity: Int64($0.quantity), flag: $0.flag)
        }
        
        return try add(ship: DGMTypeID(fitting.shipTypeID), items: items, skillLevels: skillLevels)
    }
    
    init(gang: DGMGang) {
        self.gang = gang
        self.loadouts = [:]
    }
    
    convenience init(fleet: Fleet, configuration: FleetConfiguration, skillLevels: [URL: DGMSkillLevels]) throws {
        try self.init()
        try (fleet.loadouts?.allObjects as? [Loadout])?.forEach {
            let pilot = try add(loadout: $0, skillLevels: .level(5)).parent as? DGMCharacter
            if let url = pilot?.url, let skills = skillLevels[url] {
                pilot?.setSkillLevels(skills)
            }
        }
        gang.fleetConfiguration = configuration
        self.fleet = fleet
    }
    
    func save(managedObjectContext: NSManagedObjectContext) {
        let pilots = gang.pilots
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
            fleet?.configuration = try? JSONEncoder().encode(gang.fleetConfiguration)
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
