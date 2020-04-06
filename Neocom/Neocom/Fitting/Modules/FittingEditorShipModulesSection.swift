//
//  FittingEditorShipModulesSection.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible

struct FittingEditorShipModulesSection: View {
    private struct GroupKey: Hashable {
        var typeID: DGMTypeID
        var state: DGMModule.State
        var charge: DGMTypeID?
        var target: DGMShip?
    }
    
    private enum Row: Identifiable {
        case modules([DGMModule])
        case socket(Int)
        
        var id: AnyHashable {
            switch self {
            case let .modules(modules):
                return modules
            case let .socket(socket):
                return socket
            }
        }
        
        var modules: [DGMModule]? {
            switch self {
            case let .modules(modules):
                return modules
            case .socket:
                return nil
            }
        }
        
        var socket: Int? {
            switch self {
            case .modules:
                return nil
            case let .socket(socket):
                return socket
            }
        }

    }
    
    var slot: DGMModule.Slot
    @Binding var selection: FittingEditorShipModules.Selection?
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @State private var grouped = false
    @EnvironmentObject var typePickerState: TypePickerState
    @EnvironmentObject var ship: DGMShip

    var body: some View {
        let modules = ship.modules(slot: slot)
        let n = ship.totalSlots(slot)

        var rows: [Row]
        
        if grouped {
            let groups = Dictionary(grouping: modules, by: {GroupKey(typeID: $0.typeID, state: $0.state, charge: $0.charge?.typeID, target: $0.target)}).values
                .map{($0.map{$0.socket}.min() ?? 0, $0)}
                .sorted{$0.0 < $1.0}
                .map{$1}
            rows = groups.map{Row.modules($0)}
            if ship.freeSlots(slot) > 0 {
                rows.append(.socket(-1))
            }
        }
        else {
            rows = (0..<n).map{Row.socket($0)}
            for module in modules {
                guard module.socket >= 0 else {continue}
                if module.socket >= rows.count {
                    rows += (rows.count...module.socket).map{Row.socket($0)}
                }
                rows[module.socket] = .modules([module])
            }
        }
        
        
        let header = HStack {
            slot.image.map{Icon($0, size: .small)}
            Text(slot.title?.uppercased() ?? "")
            Spacer()
            Button(grouped ? "UNGROUP" : "GROUP" ) {
                self.grouped.toggle()
            }
        }
        
        return Section(header: header) {
            ForEach(rows) { i in
                if i.modules?.isEmpty == false {
                    Button(action: {self.selection = .module(DGMModuleGroup(i.modules!))}) {
                        FittingModuleCell(module: DGMModuleGroup(i.modules!))
                            .foregroundColor(i.modules![0].socket >= n ? .red : nil)
                    }.buttonStyle(PlainButtonStyle())
                }
                else {
                    Button(action: {
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
                            subcategory = Int(SDECategoryID.module.rawValue)
                            race = nil
                        }
                        guard let group = try? self.managedObjectContext.fetch(SDEDgmppItemGroup.rootGroup(slot: self.slot, subcategory: subcategory, race: race)).first else {return}

                        if self.grouped {
                            let sockets = IndexSet(0..<n).subtracting(IndexSet(modules.map{$0.socket}))
                            self.selection = .slot(group, sockets)
                        }
                        else {
                            self.selection = .slot(group, IndexSet(integer: i.socket!))
                        }
                    }) {
                        FittingModuleSlot(slot: self.slot)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}


struct FittingEditorShipModulesSection_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                FittingEditorShipModulesSection(slot: .hi, selection: .constant(nil))
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(DGMShip.testDominix())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(TypePickerState())
//        .colorScheme(.dark)
    }
}
