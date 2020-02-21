//
//  Dgmpp+Extension.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import CoreData
import Expressible
import Combine

extension DGMType {
    func type(from managedObjectContext: NSManagedObjectContext) -> SDEInvType? {
        try? managedObjectContext.from(SDEInvType.self)
            .filter(/\SDEInvType.typeID == Int32(self.typeID))
            .first()
    }
}


extension DGMModule.Slot {
    var image: Image? {
        switch self {
        case .hi:
            return Image("slotHigh")
        case .med:
            return Image("slotMed")
        case .low:
            return Image("slotLow")
        case .rig:
            return Image("slotRig")
        case .subsystem:
            return Image("slotSubsystem")
        case .service:
            return Image("slotService")
        case .mode:
            return Image("slotSubsystem")
        default:
            return nil
        }
    }
    
    var title: String? {
        switch self {
        case .hi:
            return NSLocalizedString("Hi Slot", comment: "")
        case .med:
            return NSLocalizedString("Med Slot", comment: "")
        case .low:
            return NSLocalizedString("Low Slot", comment: "")
        case .rig:
            return NSLocalizedString("Rig Slot", comment: "")
        case .subsystem:
            return NSLocalizedString("Subsystem Slot", comment: "")
        case .service:
            return NSLocalizedString("Service Slot", comment: "")
        case .mode:
            return NSLocalizedString("Tactical Mode", comment: "")
        default:
            return nil
        }
    }
    
    var name: String? {
        switch self {
        case .hi:
            return "Hi Slot"
        case .med:
            return "Med Slot"
        case .low:
            return "Low Slot"
        case .rig:
            return "Rig Slot"
        case .subsystem:
            return "Subsystem Slot"
        case .service:
            return "Service Slot"
        case .mode:
            return "Tactical Mode"
        default:
            return nil
        }
    }
    
    init?(name: String) {
        if name.range(of: "hi slot")?.lowerBound == name.startIndex {
            self = .hi
        }
        else if name.range(of: "med slot")?.lowerBound == name.startIndex {
            self = .med
        }
        else if name.range(of: "low slot")?.lowerBound == name.startIndex {
            self = .low
        }
        else if name.range(of: "rig slot")?.lowerBound == name.startIndex {
            self = .rig
        }
        else if name.range(of: "subsystem slot")?.lowerBound == name.startIndex {
            self = .subsystem
        }
        else if name.range(of: "service slot")?.lowerBound == name.startIndex {
            self = .service
        }
        else {
            return nil
        }
    }
}

extension DGMModule.State {
    var image: Image? {
        switch self {
        case .offline:
            return Image("offline")
        case .online:
            return Image("online")
        case .active:
            return Image("active")
        case .overloaded:
            return Image("overheated")
        default:
            return nil
        }
    }
    
    var title: String? {
        switch self {
        case .offline:
            return NSLocalizedString("Offline", comment: "")
        case .online:
            return NSLocalizedString("Online", comment: "")
        case .active:
            return NSLocalizedString("Active", comment: "")
        case .overloaded:
            return NSLocalizedString("Overheated", comment: "")
        default:
            return nil
        }
    }
}

enum DGMAccuracy {
    case none
    case low
    case average
    case good
}

extension DGMAccuracy {
    var color: Color? {
        switch self {
        case .none:
            return nil
        case .low:
            return Color(.systemRed)
        case .average:
            return Color(.systemYellow)
        case .good:
            return Color(.systemGreen)
        }
    }
}

extension DGMModule {
    func accuracy(targetSignature: DGMMeter, hitChance: DGMPercent = 0.75) -> DGMAccuracy{
        guard let ship = parent as? DGMShip else {return .none}
        
        let optimal = self.optimal
        let falloff = self.falloff
        let angularVelocity = self.angularVelocity(targetSignature: targetSignature, hitChance: hitChance) * DGMSeconds(1)
        guard angularVelocity > 0 else {return .none}
        
        let v0 = ship.maxVelocityInOrbit(optimal) * DGMSeconds(1)
        let v1 = ship.maxVelocityInOrbit(optimal + falloff) * DGMSeconds(1)
        if angularVelocity * optimal > v0 {
            return .good
        }
        else if angularVelocity * (optimal + falloff) > v1 {
            return .average
        }
        else {
            return .low
        }
    }
}

#if DEBUG
extension DGMGang {
    static func testGang(_ pilots: Int = 1) -> DGMGang {
        let gang = try! DGMGang()
        for _ in 0..<pilots {
            gang.add(.testCharacter())
        }
        return gang
    }
}

extension DGMCharacter {
    static func testCharacter() -> DGMCharacter {
        let pilot = try! DGMCharacter()
        pilot.ship = .testDominix()
        return pilot
    }
}

extension DGMShip {
    static func testDominix() -> DGMShip {
        let dominix = try! DGMShip(typeID: 645)
        try! dominix.add(DGMModule(typeID: 3154))
        try! dominix.add(DGMModule(typeID: 405))
        try! dominix.add(DGMModule(typeID: 3154))
        return dominix
    }
}

#endif

