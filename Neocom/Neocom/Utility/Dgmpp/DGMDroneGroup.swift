//
//  DGMDroneGroup.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/4/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp
import Combine
import CoreData

class DGMDroneGroup: ObservableObject {
    var drones: [DGMDrone] {
        didSet {
            objectWillChange.send()
            subscription = drones.first?.objectWillChange.sink { [weak self] in
                self?.objectWillChange.send()
            }
        }
    }

    var objectWillChange = ObservableObjectPublisher()
    
    private var subscription: AnyCancellable?
    
    init<T: Collection>(_ drones: T) where T.Element == DGMDrone {
        self.drones = Array(drones)
        assert(!drones.isEmpty)
        subscription = self.drones.first?.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
    }

    var isActive: Bool {
        get {
            drones.first?.isActive ?? false
        }
        set {
            drones.forEach{$0.isActive = newValue}
        }
    }
    
    var hasKamikazeAbility: Bool {
        drones.first?.hasKamikazeAbility ?? false
    }

    var isKamikaze: Bool {
        get {
            drones.first?.isKamikaze ?? false
        }
        set {
            drones.forEach{$0.isKamikaze = newValue}
        }
    }

    var charge: DGMCharge? {
        drones.first?.charge
    }
    
    var squadron: DGMDrone.Squadron {
        drones.first?.squadron ?? .none
    }
    
    var squadronSize: Int {
        drones.first?.squadronSize ?? 0
    }
    
    var squadronTag: Int {
        drones.first?.squadronTag ?? 0
    }
    
    var target: DGMShip? {
        get {
            drones.first?.target
        }
        set {
            drones.forEach{$0.target = newValue}
        }
    }
    
    var cycleTime: TimeInterval {
        drones.first?.cycleTime ?? 0
    }
    
    var volley: DGMDamageVector {
        drones.first?.volley ?? DGMDamageVector.zero
    }
    
    func dps(target: DGMHostileTarget = DGMHostileTarget.default) -> DGMDamagePerSecond {
        drones.first?.dps(target: target) ?? DGMDamagePerSecond(DGMDamageVector.zero)
    }
    
    var optimal: DGMMeter {
        drones.first?.optimal ?? 0
    }
    
    var falloff: DGMMeter {
        drones.first?.falloff ?? 0
    }

    var accuracyScore: DGMPoints {
        drones.first?.accuracyScore ?? 0
    }

    var miningYield: DGMCubicMeterPerSecond {
        drones.first?.miningYield ?? DGMCubicMeterPerSecond(0)
    }

    var velocity: DGMMetersPerSecond {
        drones.first?.velocity ?? DGMMetersPerSecond(0)
    }
    
    var typeID: DGMTypeID {
        drones.first?.typeID ?? 0
    }
    
    var parent: DGMType? {
        drones.first?.parent
    }

    func type(from managedObjectContext: NSManagedObjectContext) -> SDEInvType? {
        drones.first?.type(from: managedObjectContext)
    }
    
    var count: Int {
        get {
            drones.count
        }
        set {
            guard let ship = parent as? DGMShip else {return}
            
            if newValue < drones.count {
                drones[newValue...].forEach { ship.remove($0) }
                drones = Array(drones[..<newValue])
            }
            else if newValue > drones.count {
                let typeID = self.typeID
                let squadronTag = self.squadronTag
                let target = self.target
                let isActive = self.isActive
                let isKamikaze = self.isKamikaze
                
                do {
                    let newDrones = try (drones.count..<newValue).map { _ -> DGMDrone in
                        let drone = try DGMDrone(typeID: typeID)
                        try ship.add(drone, squadronTag: squadronTag)
                        drone.target = target
                        drone.isActive = isActive
                        drone.isKamikaze = isKamikaze
                        return drone
                    }
                    drones += newDrones
                }
                catch {
                    
                }
            }
        }
    }
}
