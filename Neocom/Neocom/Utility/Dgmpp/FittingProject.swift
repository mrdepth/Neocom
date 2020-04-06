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
    var loadouts: [DGMCharacter: Loadout]
    
    
    
    convenience init(ship: DGMTypeID, skillLevels: DGMSkillLevels) throws {
        let gang = try DGMGang()
        let pilot = try DGMCharacter()
        pilot.setSkillLevels(skillLevels)
        gang.add(pilot)
        pilot.ship = try DGMShip(typeID: ship)
        self.init(gang: gang, loadouts: [:])
    }
    
    convenience init(loadout: Loadout, skillLevels: DGMSkillLevels) throws {
        let gang = try DGMGang()
        let pilot = try DGMCharacter()
        pilot.setSkillLevels(skillLevels)
        gang.add(pilot)
        pilot.ship = try DGMShip(typeID: DGMTypeID(loadout.typeID))
        pilot.ship?.name = loadout.name ?? ""
        if let data = loadout.data?.data {
            pilot.loadout = data
        }
        self.init(gang: gang, loadouts: [pilot: loadout])
    }
    
    convenience init(killmail: ESI.Killmail, skillLevels: DGMSkillLevels) throws {
        let gang = try DGMGang()
        let pilot = try DGMCharacter()
        pilot.setSkillLevels(skillLevels)
        gang.add(pilot)
        let ship = try DGMShip(typeID: DGMTypeID(killmail.victim.shipTypeID))
        pilot.ship = ship
        
        var cargo = Set<DGMTypeID>()
        var requiresAmmo = [DGMModule]()
        
        try killmail.victim.items?.forEach { item in
            let typeID = DGMTypeID(item.itemTypeID)
            let qty = max((item.quantityDropped ?? 0) + (item.quantityDestroyed ?? 0), 1)
            switch ESI.LocationFlag(rawValue: item.flag) {
            case .droneBay, .fighterBay, .fighterTube0, .fighterTube1, .fighterTube2, .fighterTube3, .fighterTube4:
                for _ in 0..<qty {
                    try ship.add(DGMDrone(typeID: typeID))
                }
            case .cargo?:
                cargo.insert(typeID)
            default:
                do {
                    for _ in 0..<max(qty, 1) {
                        let module = try DGMModule(typeID: typeID)
                        try ship.add(module, ignoringRequirements: true)
                        if (!module.chargeGroups.isEmpty) {
                            requiresAmmo.append(module)
                        }
                    }
                }
                catch {
                    cargo.insert(typeID)
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

        
        self.init(gang: gang, loadouts: [:])
    }
    
    convenience init(asset: AssetsData.Asset, skillLevels: DGMSkillLevels) throws {
        let gang = try DGMGang()
        let pilot = try DGMCharacter()
        pilot.setSkillLevels(skillLevels)
        gang.add(pilot)
        let ship = try DGMShip(typeID: DGMTypeID(asset.underlyingAsset.typeID))
        pilot.ship = ship
        ship.name = asset.assetName ?? ""
        
        var cargo = Set<DGMTypeID>()
        var requiresAmmo = [DGMModule]()

        
        for asset in asset.nested {
            
            let typeID = DGMTypeID(asset.underlyingAsset.typeID)

            let qty = max(asset.underlyingAsset.quantity, 1)
            switch asset.underlyingAsset.locationFlag {
            case .droneBay, .fighterBay, .fighterTube0, .fighterTube1, .fighterTube2, .fighterTube3, .fighterTube4:
                do {
                    for _ in 0..<qty {
                        try ship.add(DGMDrone(typeID: typeID))
                    }
                }
                catch {
                }
            case .cargo:
                cargo.insert(typeID)
            default:
                do {
                    for _ in 0..<max(qty, 1) {
                        let module = try DGMModule(typeID: typeID)
                        try ship.add(module, ignoringRequirements: true)
                        if (!module.chargeGroups.isEmpty) {
                            requiresAmmo.append(module)
                        }
                    }
                }
                catch {
                    cargo.insert(typeID)
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

        self.init(gang: gang, loadouts: [:])
    }
    init(gang: DGMGang, loadouts: [DGMCharacter: Loadout]) {
        self.gang = gang
        self.loadouts = loadouts
    }
    
    func save(managedObjectContext: NSManagedObjectContext) {
        gang.pilots.forEach { pilot in
            guard let ship = pilot.ship else {return}
            
            
            let loadout: Loadout? = loadouts[pilot] ?? {
                let isEmpty = ship.modules.isEmpty && ship.drones.isEmpty
                
                if !isEmpty {
                    let loadout = Loadout(context: managedObjectContext)
                    loadout.data = LoadoutData(context: managedObjectContext)
                    loadout.typeID = Int32(ship.typeID)
                    loadout.uuid = UUID().uuidString
                    loadouts[pilot] = loadout
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
                loadout.data?.data = pilot.loadout
            }
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FittingProject, rhs: FittingProject) -> Bool {
        lhs === rhs
    }

}
