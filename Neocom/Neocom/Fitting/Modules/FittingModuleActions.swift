//
//  FittingModuleActions.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible

struct FittingModuleTypeInfo: View {
    @ObservedObject var module: DGMModuleGroup
    var type: SDEInvType
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    @State private var isTypeVariationsPresented = false
    
    private func replace(with type: SDEInvType) {
        guard let ship = module.parent as? DGMShip else {return}
        let state = module.state
        do {
            let newModules = try module.modules.map { i -> DGMModule in
                let charge = i.charge?.typeID
                let socket = i.socket
                ship.remove(i)
                let newModule = try DGMModule(typeID: DGMTypeID(type.typeID))
                if let chargeID = charge {
                    try? newModule.setCharge(DGMCharge(typeID: DGMTypeID(chargeID)))
                }
                try ship.add(newModule, socket: socket)
                newModule.state = state
                return newModule
            }
            self.module.modules = newModules
        }
        catch {
        }
    }
    
    private var variations: some View {
        FittingTypeVariations(type: self.type) { newType in
            self.isTypeVariationsPresented = false
            self.replace(with: newType)
        }
    }
    
    var body: some View {
        NavigationLink(destination: variations, isActive: $isTypeVariationsPresented) {
            HStack(spacing: 0) {
                TypeCell(type: type)
                Spacer()
                TypeInfoButton(type: type)
            }.contentShape(Rectangle())
        }.buttonStyle(BorderlessButtonStyle())
    }
}

struct FittingChargeCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @ObservedObject var module: DGMModuleGroup
    var charge: SDEDgmppItemDamage?
    
    var body: some View {
        let type = charge?.item?.type ?? module.charge?.type(from: managedObjectContext)
        
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                type.map {Icon($0.image).cornerRadius(4)}
                
                Text(type?.typeName ?? "")
                Text("x\(UnitFormatter.localizedString(from: module.charges, unit: .none, style: .long))").modifier(SecondaryLabelModifier())
            }
            if charge != nil {
                DamageVectorView(damage: DGMDamageVector(charge!))
            }
        }
    }
}

struct FittingModuleActions: View {

    @ObservedObject var module: DGMModuleGroup
    var completion: () -> Void

    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    @State private var selectedType: SDEInvType?
    @State private var selectedChargeCategory: SDEDgmppItemCategory?
    
    private func chargeCell(_ type: SDEInvType, chargeCategory: SDEDgmppItemCategory) -> some View {
        HStack(spacing: 0) {
            FittingChargeCell(module: module, charge: type.dgmppItem?.damage)
            Spacer()
            TypeInfoButton(type: type)
        }.contentShape(Rectangle())
    }
    
    private func typeInfo(_ type: SDEInvType) -> some View {
        NavigationView {
            TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
        }
        .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var removeChargeButton: some View {
        BarButtonItems.trash {
            try? self.module.setCharge(nil)
            self.selectedChargeCategory = nil
        }
    }

    private func charges(_ category: SDEDgmppItemCategory) -> some View {
//        NavigationView {
            FittingCharges(category: category) { type in
                do {
                    let charge = try DGMCharge(typeID: DGMTypeID(type.typeID))
                    try self.module.setCharge(charge)
                }
                catch {
                }
                self.selectedChargeCategory = nil
            }
            .navigationBarItems(//leading: BarButtonItems.close {self.selectedChargeCategory = nil},
                                trailing: self.module.charge != nil ? removeChargeButton : nil)
//        }
//        .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
//        .navigationViewStyle(StackNavigationViewStyle())
//        .frame(idealWidth: 375, idealHeight: 375 * 2)
    }

    private func replace(with type: SDEInvType) {
        guard let ship = module.parent as? DGMShip else {return}
        do {
            let newModules = try module.modules.map { i -> DGMModule in
                let charge = i.charge?.typeID
                let socket = i.socket
                ship.remove(i)
                let newModule = try DGMModule(typeID: DGMTypeID(type.typeID))
                if let chargeID = charge {
                    try? module.setCharge(DGMCharge(typeID: DGMTypeID(chargeID)))
                }
                try ship.add(newModule, socket: socket)
                return newModule
            }
            self.module.modules = newModules
        }
        catch {
            
        }
    }
    
    private func delete() {
        guard let ship = module.parent as? DGMShip else {return}
        module.modules.forEach{ship.remove($0)}
    }

    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self)
            .filter(/\SDEInvType.typeID == Int32(module.typeID)).first()
        let charge = module.charge?.type(from: managedObjectContext)
        return List {
            Section(header: Text("MODULE")) {
                type.map{
                    FittingModuleTypeInfo(module: module, type: $0)
                }
                if module.availableStates.count > 1 {
                    FittingModuleState(module: module)
                }
            }
            type?.dgmppItem?.charge.map { chargeCategory in
                Section(header: Text("CHARGE")) {
                    NavigationLink(destination: self.charges(chargeCategory), tag: chargeCategory, selection: $selectedChargeCategory) {
                        if charge != nil {
                            self.chargeCell(charge!, chargeCategory: chargeCategory)
                        }
                        else {
//                            Button(action: {self.selectedChargeCategory = chargeCategory}) {
                                Text("Select Ammo")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(minHeight: 30)
                                    .contentShape(Rectangle())
//                            }
                        }
                    }.buttonStyle(BorderlessButtonStyle())
                }
            }
        }.listStyle(GroupedListStyle())
            .navigationBarTitle("Actions")
            .navigationBarItems(leading: BarButtonItems.close(completion), trailing: BarButtonItems.trash {
                self.completion()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    let ship = self.module.parent as? DGMShip
                    self.module.modules.forEach { ship?.remove($0) }
                }
            })
            .sheet(item: $selectedType) { self.typeInfo($0)}
//        .popover(item: $selectedChargeCategory) { self.charges($0) }
    }
}

struct FittingModuleActions_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let module = gang.pilots.first?.ship?.modules.first
        return NavigationView {
            FittingModuleActions(module: DGMModuleGroup([module!])) {}
        }
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(SharedState.testState())
    }
}
