//
//  DNA.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/7/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp

struct DNALoadoutDecoder: LoadoutDecoder {
    func decode(from data: Data) throws -> Ship {
        guard let dna = String(data: data, encoding: .utf8) else {throw RuntimeError.invalidDNAFormat}
        var components = dna.components(separatedBy: ":")
        guard components.count > 1, let shipID = Int(components[0]) else {throw RuntimeError.invalidDNAFormat}
        components.removeFirst()
        
        var modules = [DGMModule.Slot: [Ship.Module]]()
        
        let slots: [DGMModule.Slot] = [.subsystem, .hi, .med, .low, .rig, .service]
        zip(components, slots).forEach { i in
            let c = i.0.components(separatedBy: ";")
            guard c.count > 1 else {return}
            guard let typeID = Int(c[0]) else {return}
            let qty = c.count > 1 ? (Int(c[1]) ?? 1) : 1
            let module = Ship.Module(typeID: typeID, count: qty)
            modules[i.1, default: []].append(module)
        }
        
        return Ship(typeID: shipID, modules: modules)
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

