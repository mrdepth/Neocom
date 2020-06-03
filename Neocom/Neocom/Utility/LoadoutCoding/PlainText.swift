//
//  PlainText.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/16/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import Expressible
import Dgmpp

private let slotsOrder: [DGMModule.Slot] = [.low, .med, .hi, .rig, .subsystem, .service]

struct LoadoutPlainTextEncoder: LoadoutEncoder {
    var managedObjectContext: NSManagedObjectContext

    func encode(_ ship: Ship) throws -> Data {
        guard let shipType = try managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(ship.typeID)).first() else {throw RuntimeError.invalidLoadoutFormat}
        
        let typeName = shipType.originalTypeName ?? ""
        let shipName = ship.name?.isEmpty == false ? ship.name : typeName
        var output = "[\(typeName), \(shipName ?? "")]\n"

        for slot in slotsOrder {
            ship.modules?[slot]?.forEach { module in
                guard let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(module.typeID)).first() else {return}
                let s = type.typeName ?? ""
                for _ in 0..<module.count {
                    output += s + "\n"
                }
            }
            output += "\n"
        }
         
        let drones = Dictionary(ship.drones?.map{($0.typeID, $0.count)} ?? [],
                                 uniquingKeysWith: {a, b in a + b})

        let charges = Dictionary(ship.modules?.values.joined().compactMap{$0.charge}.map{($0.typeID, $0.count)} ?? [],
                                 uniquingKeysWith: {a, b in a + b})

        var cargo = Dictionary(ship.cargo?.map{($0.typeID, $0.count)} ?? [],
                               uniquingKeysWith: {a, b in a + b})
        
        cargo.merge(charges) {$0 + $1}
        
        func dump(_ items: [Int: Int]) -> String {
            items.compactMap { (typeID, count) -> String? in
                guard let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(typeID)).first() else {return nil}
                return "\(type.originalTypeName ?? "") x\(count)"
            }.joined(separator: "\n")
        }
        
        if !drones.isEmpty {
            output += dump(drones) + "\n\n"
        }
        if !cargo.isEmpty {
            output += dump(cargo) + "\n"
        }
        
        guard let data = output.data(using: .utf8) else {throw RuntimeError.invalidLoadoutFormat}
        return data
    }
}

struct LoadoutPlainTextDecoder: LoadoutDecoder {
    var managedObjectContext: NSManagedObjectContext
    
    func decode(from data: Data) throws -> Ship {
        guard let string = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {throw RuntimeError.invalidLoadoutFormat}
        
        func getType<T: StringProtocol>(_ name: T) throws -> SDEInvType? {
            try managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.originalTypeName == String(name)).first()
        }
        
        let re0 = try! NSRegularExpression(pattern: "\\[\\s*(.*?)\\s*,\\s*(.*?)\\s*\\]", options: [])
        let re1 = try! NSRegularExpression(pattern: "(.*)\\s+x(\\d*)", options: [])
        let re2 = try! NSRegularExpression(pattern: "x(\\d*)\\s+(.*)", options: [])
        
        func extractRow(_ s: String) throws -> (SDEInvType, Int) {
            let typeName: String
            let nsString = s as NSString
            let count: Int
            if let match = re1.matches(in: s, options: [], range: NSRange(location: 0, length: s.count)).first {
                typeName = nsString.substring(with: match.range(at: 1))
                count = Int(nsString.substring(with: match.range(at: 2))) ?? 1
            }
            else if let match = re2.matches(in: s, options: [], range: NSRange(location: 0, length: s.count)).first {
                typeName = nsString.substring(with: match.range(at: 2))
                count = Int(nsString.substring(with: match.range(at: 1))) ?? 1
            }
            else {
                typeName = s
                count = 1
            }
            guard let type = try getType(typeName) else {throw RuntimeError.invalidLoadoutFormat}
            return (type, count)
        }
        
        let rows = string.components(separatedBy: "\n")
        if let s = rows.first, let match = re0.matches(in: s, options: [], range: NSRange(location: 0, length: s.count)).first {
            let nsString = s as NSString
            let typeName = nsString.substring(with: match.range(at: 1))
            let shipName = nsString.substring(with: match.range(at: 2))
            guard let shipType = try getType(typeName) else {throw RuntimeError.invalidLoadoutFormat}

            
            let groups = rows.dropFirst().split(separator: "", maxSplits: .max, omittingEmptySubsequences: false)
            
            let modules = Dictionary(zip(slotsOrder, groups)) {a, _ in a}
                .mapValues { rows in
                    rows.filter{!$0.hasPrefix("[")}.compactMap {try? extractRow($0)}.map {
                        Ship.Module(typeID: Int($0.0.typeID), count: $0.1)
                    }
            }.filter{!$0.value.isEmpty}
            
            var remains = groups.dropFirst(slotsOrder.count)
            let drones = remains.first?.compactMap{try? extractRow($0)}.map{Ship.Drone(typeID: Int($0.0.typeID), count: $0.1)}
            remains = remains.dropFirst()
            let cargo = remains.joined().compactMap{try? extractRow($0)}.map{Ship.Item(typeID: Int($0.0.typeID), count: $0.1)}
            
            return Ship(typeID: Int(shipType.typeID), name: shipName.isEmpty ? nil : shipName, modules: modules, drones: drones, cargo: cargo, implants: nil, boosters: nil)
        }
        else {
            throw RuntimeError.invalidLoadoutFormat
        }
    }
}
