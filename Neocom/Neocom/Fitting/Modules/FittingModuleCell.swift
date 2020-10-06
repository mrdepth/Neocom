//
//  FittingModuleCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible

struct FittingModuleBaseCell: View {
    
    @ObservedObject var ship: DGMShip
    var slot: DGMModule.Slot
    var module: DGMModuleGroup?
    var sockets: IndexSet

    @State private var isActionsPresented = false
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.typePicker) private var typePicker
    @Environment(\.managedObjectContext) private var managedObjectContext

    private var group: SDEDgmppItemGroup? {
        let subcategory: Int?
        let race: SDEChrRace?
        switch self.slot {
        case .rig:
            subcategory = self.ship.rigSize.rawValue
            race = nil
        case .subsystem:
            subcategory = nil
            race = try? self.managedObjectContext.from(SDEChrRace.self).filter(/\SDEChrRace.raceID == Int32(self.ship.raceID.rawValue)).first()
        case .mode:
            subcategory = self.ship.typeID
            race = nil
        default:
            subcategory = Int(self.ship is DGMStructure ? SDECategoryID.structureModule.rawValue : SDECategoryID.module.rawValue)
            race = nil
        }
        return try? self.managedObjectContext.fetch(SDEDgmppItemGroup.rootGroup(slot: self.slot, subcategory: subcategory, race: race, structure: self.ship is DGMStructure)).first
    }
    
    private func typePicker(_ group: SDEDgmppItemGroup, sockets: IndexSet) -> some View {
        typePicker.get(group, environment: environment, sharedState: sharedState) {
            self.isActionsPresented = false
            guard let type = $0 else {return}
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                do {
                    for i in sockets {
                        let module = try DGMModule(typeID: DGMTypeID(type.typeID))
                        try self.ship.add(module, socket: i)
                    }
                }
                catch {
                }
            }
        }
    }
    
    var body: some View {
        Button(action: {self.isActionsPresented = true}) {
            if module != nil {
                FittingModuleCell(ship: ship, module: module!)
            }
            else {
                FittingModuleSlot(slot: slot)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .adaptivePopover(isPresented: $isActionsPresented, arrowEdge: .leading) {
            if self.module != nil {
                NavigationView {
                    FittingModuleActions(module: self.module!) {
                        self.isActionsPresented = false
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
                .frame(idealWidth: 375, idealHeight: 375 * 2)
            }
            else {
                self.group.map {
                    self.typePicker($0, sockets: IndexSet(integer: -1))
                }
            }
        }

    }
}

struct FittingModuleCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @ObservedObject var ship: DGMShip
    @ObservedObject var module: DGMModuleGroup

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
                    Text(UnitFormatter.localizedString(from: cycleTime, unit: .seconds, style: .long)).fontWeight(.semibold)
//                    Text(TimeIntervalFormatter.localizedString(from: cycleTime, precision: .seconds)).fontWeight(.semibold)
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
    
    private var charge: some View {
        let charge = module.charge?.type(from: managedObjectContext)
        return Group {
            if charge != nil {
                HStack(spacing: 0) {
                    Icon(charge!.image, size: .small)
                    Text(" \(charge?.typeName ?? "") ") + Text("x\(module.charges)").fontWeight(.semibold)
                }.modifier(SecondaryLabelModifier())
            }
        }
    }

    var body: some View {
        let type = module.type(from: managedObjectContext)
        let slotsWithState: Set<DGMModule.Slot> = [.hi, .low, .med, .starbaseStructure]
        
        return  HStack {
            (type?.image).map{Icon($0).cornerRadius(4)}
            VStack(alignment: .leading, spacing: 0) {
                (type?.typeName).map{Text($0)} ?? Text("Unknown")
                charge
                OptimalInfo(optimal: module.optimal, falloff: module.falloff).modifier(SecondaryLabelModifier())
                accuracy
                cycleTime
                lifeTime
            }
            Spacer()
            HStack(spacing: 0) {
                if module.target != nil {
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
        .contentShape(Rectangle())
        .contextMenu {
            ForEach(module.availableStates, id: \.self) { i in
                Button(action: {self.module.state = i}) {
                    i.title.map{Text($0)}
//                    i.image
                }
            }
            Button(action: {
                for module in self.module.modules {
                    self.ship.remove(module)
                }
            }) {
                Text("Delete")
                Image(uiImage: UIImage(systemName: "trash")!)
            }
        }
    }
    
    @State private var pick = "Some"
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
            FittingModuleCell(ship: dominix, module: DGMModuleGroup([cannon]))
        }.listStyle(GroupedListStyle())
        .modifier(ServicesViewModifier.testModifier())
        .environmentObject(gang)
    }
}
