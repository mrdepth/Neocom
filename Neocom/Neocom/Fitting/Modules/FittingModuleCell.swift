//
//  FittingModuleCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingModuleCell: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @ObservedObject var module: DGMModuleGroup
    
    private var optimal: some View {
        let optimal = module.optimal
        let falloff = module.falloff
        
        return Group {
            if optimal > 0 {
                HStack(spacing: 0) {
                    Icon(Image("targetingRange"), size: .small)
                    if falloff > 0 {
                        Text(" optimal + falloff: ") +
                        Text(UnitFormatter.localizedString(from: optimal, unit: .meter, style: .long)).fontWeight(.semibold) +
                        Text(" + ") +
                        Text(UnitFormatter.localizedString(from: falloff, unit: .meter, style: .long)).fontWeight(.semibold)
                    }
                    else {
                        Text(" optimal: \(UnitFormatter.localizedString(from: optimal, unit: .meter, style: .long))")
                    }
                }.modifier(SecondaryLabelModifier())
            }
        }
    }
    
    private var accuracy: some View {
        let ship = module.parent as? DGMShip
        let signature = ship?[Int(SDEAttributeID.signatureRadius.rawValue)]?.initialValue ?? 0
        let accuracy = module.accuracy(targetSignature: signature)
        let color = accuracy.color
        
        func description(ship: DGMShip) -> some View{
            let accuracyScore = module.accuracyScore
            let angularVelocity = module.angularVelocity(targetSignature: signature)
            let orbitRadius = ship.orbitRadius(angularVelocity: angularVelocity)
            
            let accuracy = UnitFormatter.localizedString(from: accuracyScore, unit: .none, style: .long)
            let range = UnitFormatter.localizedString(from: orbitRadius, unit: .none, style: .long)
            
            return HStack(spacing: 0) {
                Icon(Image("tracking"), size: .small)
                Text(" accuracy: ") + Text(accuracy).fontWeight(.semibold).foregroundColor(color) + Text(" (")
                Icon(Image("targetingRange"), size: .small)
                Text(" \(range)+ m").fontWeight(.semibold).foregroundColor(color) + Text(")")
            }
        }
        
        return Group {
            if (ship != nil && accuracy != .none) {
                description(ship: ship!).modifier(SecondaryLabelModifier())
            }
        }
    }
    
    private var cycleTime: some View {
        let cycleTime = module.cycleTime
        
        return Group {
            if cycleTime > 0 {
                HStack(spacing: 0) {
                    Icon(Image("dps"), size: .small)
                    Text(" rate of fire: ") +
                    Text(TimeIntervalFormatter.localizedString(from: cycleTime, precision: .seconds)).fontWeight(.semibold)
                }.modifier(SecondaryLabelModifier())
            }
        }
    }

    private var lifeTime: some View {
        let lifeTime = module.lifeTime
        return Group {
            if lifeTime > 0 {
                HStack(spacing: 0) {
                    Icon(Image("overheated"), size: .small)
                    Text(" lifetime: ") +
                    Text(TimeIntervalFormatter.localizedString(from: lifeTime, precision: .seconds)).fontWeight(.semibold)
                }.modifier(SecondaryLabelModifier())
            }
        }
    }

    var body: some View {
        let type = module.type(from: managedObjectContext)
        let slotsWithState: Set<DGMModule.Slot> = [.hi, .low, .med, .starbaseStructure]

        return type.map { type in
            HStack {
                Icon(type.image)
                VStack(alignment: .leading, spacing: 0) {
                    Text(type.typeName ?? "")
                    optimal
                    accuracy
                    cycleTime
                    lifeTime
                }
                Spacer()
                HStack(spacing: 0) {
                    if module.target == nil {
                        Icon(Image("targets"), size: .small)
                    }
                    if slotsWithState.contains(module.slot) {
                        module.state.image.map{Icon($0, size: .small)}
                    }
                }
                if module.modules.count > 1 {
                    Text("x\(module.modules.count)").fontWeight(.semibold).modifier(SecondaryLabelModifier())
                }
            }
        }
    }
}

struct FittingModuleCell_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let pilot = gang.pilots[0]
        let dominix = pilot.ship!
        let cannon = try! DGMModule(typeID: 3154)
        try! dominix.add(cannon)
        cannon.state = .overloaded
        
        return List {
            FittingModuleCell(module: DGMModuleGroup([cannon]))
        }.listStyle(GroupedListStyle())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(gang)
    }
}
