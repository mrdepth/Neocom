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
