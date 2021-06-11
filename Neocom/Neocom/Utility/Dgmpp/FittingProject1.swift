//
//  FittingProject1.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/9/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp
import Combine
import SwiftUI
import CoreData
import Expressible
import EVEAPI

class FittingProject1: ObservableObject, Identifiable {

    private(set) var gang: DGMGang? {
        didSet {
            gangSubscription = gang?.objectWillChange.sink { [weak self] in self?.touch() }
        }
    }
    
    private(set) var structure: DGMStructure? {
        didSet {
            structureSubscription = structure?.objectWillChange.sink { [weak self] in self?.touch() }
        }
    }

    private var gangSubscription: AnyCancellable?
    private var structureSubscription: AnyCancellable?
    
    @Published private(set) var loadouts: [DGMShip: Loadout] = [:]
    private(set) var fleet: Fleet?
    let managedObjectContext: NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
    
    var localizedName: String {
        if let ships = gang?.pilots.compactMap({$0.ship}), let ship = ships.first {
            let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(ship.typeID)).first()
            let typeName = type?.typeName ?? ""
            if ships.count > 1 {
                return "\(typeName) and \(ships.count - 1) more"
            }
            else {
                let shipName = ship.name.isEmpty ? typeName : ship.name
                return "\(typeName), \(shipName)"
            }

        }
        else if let structure = self.structure {
            let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(structure.typeID)).first()
            let typeName = type?.typeName ?? ""
            let shipName = structure.name.isEmpty ? typeName : structure.name
            return "\(typeName), \(shipName)"
        }
        else {
            return NSLocalizedString("Neocom", comment: "")
        }
    }
    
    //MARK: - Init
    
    convenience init(ship: DGMTypeID, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        self.init(managedObjectContext: managedObjectContext)
        try add(ship: ship, skillLevels: skillLevels)
    }
    
    convenience init(loadout: Loadout, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        self.init(managedObjectContext: managedObjectContext)
        try add(loadout: loadout, skillLevels: skillLevels)
    }

    convenience init(loadout: Ship, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        self.init(managedObjectContext: managedObjectContext)
        try add(loadout: loadout, skillLevels: skillLevels)
    }

    convenience init(killmail: ESI.Killmail, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        self.init(managedObjectContext: managedObjectContext)
        try add(killmail: killmail, skillLevels: skillLevels)
    }
    
    convenience init(asset: AssetsData.Asset, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        self.init(managedObjectContext: managedObjectContext)
        try add(asset: asset, skillLevels: skillLevels)
    }
    
    convenience init(fitting: ESI.Fittings.Element, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        self.init(managedObjectContext: managedObjectContext)
        try add(fitting: fitting, skillLevels: skillLevels)
    }
    
    convenience init(gang: DGMGang, managedObjectContext: NSManagedObjectContext) {
        self.init(managedObjectContext: managedObjectContext)
        self.gang = gang
        self.loadouts = [:]
    }
    
    convenience init(fleet: Fleet, configuration: FleetConfiguration, skillLevels: [URL: DGMSkillLevels], managedObjectContext: NSManagedObjectContext) throws {
        self.init(managedObjectContext: managedObjectContext)
        try (fleet.loadouts?.allObjects as? [Loadout])?.forEach {
            let pilot = try add(loadout: $0, skillLevels: .level(5)).parent as? DGMCharacter
            if let url = pilot?.url, let skills = skillLevels[url] {
                pilot?.setSkillLevels(skills)
            }
        }
        gang?.fleetConfiguration = configuration
        self.fleet = fleet
    }
    
    convenience init(dna: String, skillLevels: DGMSkillLevels, managedObjectContext: NSManagedObjectContext) throws {
        guard let data = dna.data(using: .utf8) else {throw RuntimeError.invalidDNAFormat}
        let ship = try DNALoadoutDecoder(managedObjectContext: managedObjectContext).decode(from: data)
        self.init(managedObjectContext: managedObjectContext)
        try add(ship: DGMTypeID(ship.typeID), skillLevels: skillLevels).loadout = ship
    }
    
    //MARK: - Add
    
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
    
    @discardableResult
    func add(loadout: Ship, skillLevels: DGMSkillLevels) throws -> DGMShip {
        let ship = try add(ship: DGMTypeID(loadout.typeID), skillLevels: skillLevels)
        
        ship.name = loadout.name ?? ""
        if let pilot = ship.parent as? DGMCharacter {
            pilot.loadout = loadout
        }
        else {
            ship.loadout = loadout
        }
        return ship
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
    
    @discardableResult
    func add(asset: AssetsData.Asset, skillLevels: DGMSkillLevels) throws -> DGMShip {
        let items = asset.nested.map {
            (typeID: DGMTypeID($0.underlyingAsset.typeID), quantity: Int64($0.underlyingAsset.quantity), flag: $0.underlyingAsset.location)
        }
        
        return try add(ship: DGMTypeID(asset.underlyingAsset.typeID), items: items, skillLevels: skillLevels)
    }
    
    @discardableResult
    func add(fitting: ESI.Fittings.Element, skillLevels: DGMSkillLevels) throws -> DGMShip {
        let items = fitting.items.map {
            (typeID: DGMTypeID($0.typeID), quantity: Int64($0.quantity), flag: $0.flag)
        }
        
        return try add(ship: DGMTypeID(fitting.shipTypeID), items: items, skillLevels: skillLevels)
    }
    
    //MARK: - Save
    
    func save() {
        managedObjectContext.perform {
            self.gang?.pilots.forEach {
                self.save($0)
            }
            self.saveFleet()
            if let structure = self.structure {
                self.save(structure)
            }
            if self.managedObjectContext.hasChanges {
                try? self.managedObjectContext.save()
            }
        }
    }
    
    private func save(_ pilot: DGMCharacter) {
        guard let ship = pilot.ship else {return}

        let loadout: Loadout? = self.loadouts[ship] ?? {
            let loadout = Loadout(context: self.managedObjectContext)
            loadout.data = LoadoutData(context: self.managedObjectContext)
            loadout.typeID = Int32(ship.typeID)
            loadout.uuid = UUID().uuidString
            self.loadouts[ship] = loadout
            return loadout
            }()
        if let loadout = loadout, !loadout.isDeleted && loadout.managedObjectContext != nil {
            if loadout.name != ship.name {
                loadout.name = ship.name
            }
            if loadout.data == nil {
                loadout.data = LoadoutData(context: self.managedObjectContext)
            }
            loadout.ship = pilot.loadout
        }
    }
    
    private func save(_ structure: DGMStructure) {
        let loadout: Loadout? = self.loadouts[structure] ?? {
            let loadout = Loadout(context: self.managedObjectContext)
            loadout.data = LoadoutData(context: self.managedObjectContext)
            loadout.typeID = Int32(structure.typeID)
            loadout.uuid = UUID().uuidString
            self.loadouts[structure] = loadout
            return loadout
        }()
        if let loadout = loadout, !loadout.isDeleted && loadout.managedObjectContext != nil {
            if loadout.name != structure.name {
                loadout.name = structure.name
            }
            if loadout.data == nil {
                loadout.data = LoadoutData(context: self.managedObjectContext)
            }
            loadout.ship = structure.loadout
        }
    }
    
    private func saveFleet() {
        let pilots = gang?.pilots ?? []
        
        if pilots.count > 1 {
            if self.fleet == nil {
                self.fleet = Fleet(context: self.managedObjectContext)
            }
            let data = self.gang.flatMap{try? JSONEncoder().encode($0.fleetConfiguration)}
            if self.fleet?.configuration != data {
                self.fleet?.configuration = data
            }
            
            let fleetLoadouts = Set(self.fleet?.loadouts?.allObjects as? [Loadout] ?? [])
            fleetLoadouts.subtracting(self.loadouts.values).forEach {
                self.fleet?.removeFromLoadouts($0)
            }
            Set(self.loadouts.values).subtracting(fleetLoadouts).forEach {
                self.fleet?.addToLoadouts($0)
            }
            let name = pilots.compactMap{$0.ship}.compactMap{$0.type(from: self.managedObjectContext)?.typeName}.joined(separator: ", ")
            if self.fleet?.name != name {
                self.fleet?.name = name
            }
            
        }
        else {
            if let fleet = self.fleet {
                self.managedObjectContext.delete(fleet)
                self.fleet = nil
            }
        }
    }
    
    //MARK: - UserActivity
    
    private func touch() {
        
    }
    
    enum CodingKeys: String, CodingKey {
        case gang
        case loadouts
        case fleet
        case structure
    }
    
    struct MetaInfo: Codable {
        var gang: DGMGang?
        var structure: DGMStructure?
        var loadouts: [Int: URL]
        var fleet: URL?
    }

}
