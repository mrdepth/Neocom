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
        case sockets(IndexSet)
        
        var id: AnyHashable {
            sockets
        }
        
        var modules: [DGMModule]? {
            switch self {
            case let .modules(modules):
                return modules
            case .sockets:
                return nil
            }
        }
        
        var sockets: IndexSet {
            switch self {
            case let .modules(modules):
                return IndexSet(modules.map{$0.socket})
            case let .sockets(sockets):
                return sockets
            }
        }

    }
    
    @ObservedObject var ship: DGMShip
    var slot: DGMModule.Slot
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @State private var grouped = false

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
                rows.append(.sockets(IndexSet(0..<n).subtracting(IndexSet(modules.map{$0.socket}))))
            }
        }
        else {
            rows = (0..<n).map{Row.sockets(IndexSet(integer: $0))}
            for module in modules {
                guard module.socket >= 0 else {continue}
                if module.socket >= rows.count {
                    rows += (rows.count...module.socket).map{Row.sockets(IndexSet(integer: $0))}
                }
                rows[module.socket] = .modules([module])
            }
        }
        
        
        let header = HStack {
            slot.image.map{Icon($0, size: .small)}
            Text(slot.title?.uppercased() ?? "")
            Spacer()
            Button(grouped ? "SPLIT" : "MERGE" ) {
                self.grouped.toggle()
            }
        }
        
        return Section(header: header) {
            ForEach(rows) { i in
                FittingModuleBaseCell(ship: self.ship, slot: self.slot, module: i.modules?.isEmpty == false ? DGMModuleGroup(i.modules!) : nil, sockets: i.sockets)
            }
        }
    }
}


struct FittingEditorShipModulesSection_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                FittingEditorShipModulesSection(ship: DGMShip.testDominix(), slot: .hi)
            }.listStyle(GroupedListStyle())
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
//        .colorScheme(.dark)
    }
}
