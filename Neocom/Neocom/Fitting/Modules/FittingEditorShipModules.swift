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
            case let .slot(group, _):
                return group.id
            case let .module(module):
                return module.id
            }
        }
        
        case slot(SDEDgmppItemGroup, IndexSet)
        case module(DGMModuleGroup)
        
        var module: DGMModuleGroup? {
            switch self {
            case let .module(module):
                return module
            default:
                return nil
            }
        }
        
        var slot: (group: SDEDgmppItemGroup, sockets: IndexSet)? {
            switch self {
            case let .slot(group, sockets):
                return (group, sockets)
            default:
                return nil
            }
        }
        
    }
    
    @State private var selection: Selection?
    @Environment(\.self) private var environment
    @EnvironmentObject private var ship: DGMShip
    @Environment(\.typePicker) private var typePicker
    
    private func typePicker(_ group: SDEDgmppItemGroup, sockets: IndexSet) -> some View {
        typePicker.get(group, environment: environment) {
            self.selection = nil
            guard let type = $0 else {return}
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
    
    private func moduleActions(_ module: DGMModuleGroup) -> some View {
        NavigationView {
            FittingModuleActions(module: module) {
                self.selection = nil
            }
        }.modifier(ServicesViewModifier(environment: self.environment))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            FittingEditorShipModulesHeader().padding(8)
            Divider()
            FittingEditorShipModulesList(selection: $selection)
        }
        .sheet(item: $selection) { selection in
            if selection.slot != nil {
                self.typePicker(selection.slot!.group, sockets: selection.slot!.sockets)
            }
            else if selection.module != nil {
                self.moduleActions(selection.module!)
            }
        }
    }
}

struct FittingEditorShipModules_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditorShipModules()
        }
//        .environmentObject(DGMStructure.testKeepstar() as DGMShip)
        .environmentObject(gang.pilots.first!.ship!)
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
