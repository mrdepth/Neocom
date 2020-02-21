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

struct FittingModuleActions: View {

    @ObservedObject var module: DGMModuleGroup

    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @State var selectedType: SDEInvType?
    @State var selectedTypeVariations: SDEInvType?
    @State var isTypeVariationsPresented = false
    
    func moduleCell(_ type: SDEInvType) -> some View {
        HStack(spacing: 0) {
            Button(action: {self.isTypeVariationsPresented = true}) {
                HStack(spacing: 0) {
                    TypeCell(type: type)
                    Spacer()
                }.contentShape(Rectangle())
            }.buttonStyle(PlainButtonStyle())
            
            InfoButton {
                self.selectedType = type
            }
            .sheet(isPresented: $isTypeVariationsPresented) { self.typeVariations(type) }
        }
    }
    
    private func typeInfo(_ type: SDEInvType) -> some View {
        NavigationView {
            TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
        }.modifier(ServicesViewModifier(environment: self.environment))
    }

    private func typeVariations(_ type: SDEInvType) -> some View {
        NavigationView {
            FittingTypeVariations(type: type) { newType in
                self.isTypeVariationsPresented = false
                self.replace(with: newType)
            }
            .navigationBarItems(leading: BarButtonItems.close {self.isTypeVariationsPresented = false})
        }.modifier(ServicesViewModifier(environment: self.environment))
    }
    
    private func replace(with type: SDEInvType) {
        guard let ship = module.parent as? DGMShip else {return}
        do {
            let newModules = try module.modules.map { i -> DGMModule in
                let charge = i.charge
                let socket = i.socket
                ship.remove(i)
                let newModule = try DGMModule(typeID: DGMTypeID(type.typeID))
                if let chargeID = charge?.typeID {
                    try module.setCharge(DGMCharge(typeID: DGMTypeID(DGMTypeID(chargeID))))
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
        
        return List {
            Section(header: Text("MODULE")) {
                type.map{ moduleCell($0) }
                if module.availableStates.count > 1 {
                    FittingModuleState(module: module)
                }
            }
            
            type?.dgmppItem?.charge.map { charge in
                Section(header: Text("CHARGE")) {
                    Button(action: {}) {
                        Text("Select Ammo")
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 30)
                            .contentShape(Rectangle())
                    }
                }
            }
        }.listStyle(GroupedListStyle())
            .navigationBarItems(leading: BarButtonItems.close {}, trailing: BarButtonItems.trash {})
            .navigationBarTitle("Actions")
            .sheet(item: $selectedType) { self.typeInfo($0)}
    }
}

struct FittingModuleActions_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let module = gang.pilots.first?.ship?.modules.first
        return NavigationView {
            FittingModuleActions(module: DGMModuleGroup([module!]))
        }
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
