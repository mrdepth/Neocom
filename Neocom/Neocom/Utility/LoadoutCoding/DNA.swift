//
//  DNA.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/7/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp
import CoreData
import Expressible

struct DNALoadoutDecoder: LoadoutDecoder {
    var managedObjectContext: NSManagedObjectContext
    
    private enum Slot {
        case module(DGMModule.Slot)
        case drone
        case cargo
    }
    
    func decode(from data: Data) throws -> Ship {
        guard let dna = String(data: data, encoding: .utf8) else {throw RuntimeError.invalidDNAFormat}
        var components = dna.components(separatedBy: ":")
        guard components.count > 1, let shipID = Int(components[0]) else {throw RuntimeError.invalidDNAFormat}
        components.removeFirst()
        
        var modules = [DGMModule.Slot: [Ship.Module]]()
        var cargo = [Int: Int]()
        var drones = [Int: Int]()

        func slot(for type: SDEInvType) -> Slot {
            for group in type.dgmppItem?.groups?.allObjects as? [SDEDgmppItemGroup] ?? [] {
                switch SDEDgmppItemCategoryID(rawValue: group.category!.category) {
                case .hi:
                    return .module(.hi)
                case .med:
                    return .module(.med)
                case .low:
                    return .module(.low)
                case .rig, .structureRig:
                    return .module(.rig)
                case .subsystem:
                    return .module(.subsystem)
                case .service:
                    return .module(.service)
                case .mode:
                    return .module(.mode)
                case .drone, .fighter, .structureFighter:
                    return .drone
                default:
                    continue
                }
            }
            return .cargo
        }
        
        
        for row in components {
            let c = row.components(separatedBy: ";")
            guard !c.isEmpty else {continue}
            guard let typeID = Int(c[0].hasSuffix("_") ? String(c[0].dropLast()) : c[0]) else {continue}
            guard let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(typeID)).first() else {continue}
            let count = c.count > 1 ? Int(c[1]) ?? 1 : 1

            if c[0].hasSuffix("_") {
                cargo[typeID, default: 0] += count
            }
            else {
                switch slot(for: type) {
                case let .module(slot):
                    modules[slot, default: []].append(Ship.Module(typeID: typeID, count: count))
                case .drone:
                    drones[typeID, default: 0] += count
                case .cargo:
                    cargo[typeID, default: 0] += count
                }
            }
        }
        
        return Ship(typeID: shipID,
             modules: modules,
             drones: drones.map{Ship.Drone(typeID: $0.key, count: $0.value)},
             cargo: cargo.map{Ship.Item(typeID: $0.key, count: $0.value)})
    }
}

struct DNALoadoutEncoder: LoadoutEncoder {
    
    func encode(_ ship: Ship) throws -> Data {
        let slots: [DGMModule.Slot] = [.subsystem, .hi, .med, .low, .rig, .service]
        var arrays = [NSCountedSet]()
        let charges = NSCountedSet()
        let drones = NSCountedSet()
        
        for slot in slots {
            let array = NSCountedSet()
            for module in ship.modules?[slot] ?? [] {
                for _ in 0..<module.count {
                    array.add(module.typeID)
                    if let charge = module.charge {
                        charges.add(charge)
                    }
                }
            }
            arrays.append(array)
        }
        
        for drone in ship.drones ?? [] {
            for _ in 0..<drone.count {
                drones.add(drone.typeID)
            }
        }
        
        arrays.append(drones)
        arrays.append(charges)
        
        var dna = "\(ship.typeID):"
        for array in arrays {
            for typeID in array.allObjects as! [Int] {
                dna += "\(typeID);\(array.count(for: typeID)):"
            }
        }
        dna += ":"
        
        guard let data = dna.data(using: .utf8) else {throw RuntimeError.invalidDNAFormat}
        return data
    }
}

extension URL {
    init?(dna: Data) {
        guard let s = String(data: dna, encoding: .utf8) else {return nil}
        self.init(string: "fitting:\(s)")
    }
}
