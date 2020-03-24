//
//  FittingEditorShipModules.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorShipModules: View {
    enum Selection: Identifiable {
        
        var id: AnyHashable {
            switch self {
            case let .slot(category, _):
                return category.id
            case let .module(module):
                return module.id
            }
        }
        
        case slot(SDEDgmppItemCategory, IndexSet)
        case module(DGMModuleGroup)
        
        var module: DGMModuleGroup? {
            switch self {
            case let .module(module):
                return module
            default:
                return nil
            }
        }
        
        var slot: (category: SDEDgmppItemCategory, sockets: IndexSet)? {
            switch self {
            case let .slot(category, sockets):
                return (category, sockets)
            default:
                return nil
            }
        }
        
    }
    
    @State private var selection: Selection?
    private let typePickerState = Cache<SDEDgmppItemCategory, TypePickerState>()
    @Environment(\.self) private var environment
    @EnvironmentObject private var ship: DGMShip
    
    private func typePicker(_ category: SDEDgmppItemCategory, sockets: IndexSet) -> some View {
        return NavigationView {
            TypePicker(category: category) { (type) in
                do {
                    for i in sockets {
                        let module = try DGMModule(typeID: DGMTypeID(type.typeID))
                        try self.ship.add(module, socket: i)
                    }
                }
                catch {
                }
                self.selection = nil
            }.navigationBarItems(leading: BarButtonItems.close {
                self.selection = nil
            })
        }.modifier(ServicesViewModifier(environment: self.environment))
            .environmentObject(typePickerState[category, default: TypePickerState()])
    }
    
    private func moduleActions(_ module: DGMModuleGroup) -> some View {
        NavigationView {
            FittingModuleActions(module: module)
                .navigationBarItems(leading: BarButtonItems.close {
                    self.selection = nil
                })
        }.modifier(ServicesViewModifier(environment: self.environment))
    }
    
    var body: some View {
        VStack(spacing: 4) {
            FittingEditorShipModulesHeader().padding(.horizontal, 8)
            FittingEditorShipModulesList()
        }
        .sheet(item: $selection) { selection in
            if selection.slot != nil {
                self.typePicker(selection.slot!.category, sockets: selection.slot!.sockets)
            }
            else if selection.module != nil {
                self.moduleActions(selection.module!)
            }
        }
    }
}

#if DEBUG

struct FittingEditorShipModules_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditorShipModules()
        }
        .environmentObject(gang.pilots.first!.ship!)
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}

#endif
