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

struct LoadoutPlainTextEncoder: LoadoutEncoder {

    var managedObjectContext: NSManagedObjectContext

    func encode(_ ship: Ship) throws -> Data {
        let modules = Dictionary(ship.modules?.values.joined().map{($0.typeID, $0.count)} ?? [],
                                 uniquingKeysWith: {a, b in a + b})
        let drones = Dictionary(ship.drones?.map{($0.typeID, $0.count)} ?? [],
                                 uniquingKeysWith: {a, b in a + b})

        let charges = Dictionary(ship.modules?.values.joined().compactMap{$0.charge}.map{($0.typeID, $0.count)} ?? [],
                                 uniquingKeysWith: {a, b in a + b})

        let cargo = Dictionary(ship.cargo?.map{($0.typeID, $0.count)} ?? [],
                               uniquingKeysWith: {a, b in a + b})
        
        guard let shipType = try managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(ship.typeID)).first() else {throw RuntimeError.invalidLoadoutFormat}
        
        func dump(_ items: [Int: Int]) -> String {
            items.compactMap { (typeID, count) -> String? in
                guard let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(typeID)).first() else {return nil}
                if count > 1 {
                    return "\(type.typeName ?? "") x\(count)"
                }
                else {
                    return type.typeName ?? ""
                }
            }.joined(separator: "\n")
        }
        
        let typeName = shipType.typeName ?? ""
        let shipName = ship.name?.isEmpty == false ? ship.name : typeName
        var s = "[\(typeName), \(shipName ?? "")]\n"
        if !modules.isEmpty {
            s += dump(modules) + "\n"
        }
        if !drones.isEmpty {
            s += dump(drones) + "\n"
        }
        if !charges.isEmpty {
            s += dump(charges) + "\n"
        }
        if !cargo.isEmpty {
            s += dump(cargo) + "\n"
        }
        
        guard let data = s.data(using: .utf8) else {throw RuntimeError.invalidLoadoutFormat}
        return data
    }
    
}
