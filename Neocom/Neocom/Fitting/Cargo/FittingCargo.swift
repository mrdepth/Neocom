//
//  FittingCargo.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/17/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible

struct FittingCargo: View {
    @ObservedObject var ship: DGMShip
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.self) private var environment
    @Environment(\.typePicker) private var typePicker
    @EnvironmentObject private var sharedState: SharedState
    @State private var isTypePickerPresented = false
    
    private func typePicker(_ group: SDEDgmppItemGroup) -> some View {
        typePicker.get(group, environment: environment, sharedState: sharedState) {
            self.isTypePickerPresented = false
            guard let type = $0 else {return}
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                try? self.ship.add(DGMCargo(typeID: DGMTypeID(type.typeID)))
            }
        }
    }
    
    struct Row {
        var type: SDEInvType?
        var cargo: DGMCargo
    }
    
    struct CargoSection {
        var category: SDEInvCategory?
        var rows: [Row]
    }
    
    private var group: SDEDgmppItemGroup? {
        try? self.managedObjectContext.fetch(SDEDgmppItemGroup.rootGroup(categoryID: .cargo)).first
    }

    var body: some View {
        let cargo = ship.cargo
        let invTypes = cargo.map{$0.typeID}.compactMap{try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32($0)).first()}
        let types = Dictionary(invTypes.map{($0.typeID, $0)}) {a, _ in a}

        let rows = cargo.map{Row(type: types[Int32($0.typeID)], cargo: $0)}
        
        let sections = Dictionary(grouping: rows) {$0.type?.group?.category}
            .sorted{($0.key?.categoryName ?? "") < ($1.key?.categoryName ?? "")}
            .map{ (category, rows) -> CargoSection in
                let rows = rows.sorted{($0.type?.typeName ?? "", $0.cargo.hashValue) < ($1.type?.typeName ?? "", $1.cargo.hashValue)}
                return CargoSection(category: category, rows: rows)
            }
        
        
        return VStack(spacing: 0) {
            FittingCargoHeader(ship: ship).padding(8)
            Divider()
            List {
                ForEach(sections, id: \.category) { section in
                    Section(header: section.category?.categoryName.map{Text($0.uppercased())}) {
                        ForEach(section.rows, id: \.cargo) { row in
                            FittingCargoCell(ship: self.ship, cargo: row.cargo)
                        }
                    }
                }
                Section {
                    Button(NSLocalizedString("Add Cargo", comment: "")) {
                        self.isTypePickerPresented = true
                    }
                    .frame(maxWidth: .infinity)
                    .adaptivePopover(isPresented: $isTypePickerPresented, arrowEdge: .leading) {
                        self.group.map{self.typePicker($0)}
                    }
                }
            }
            .listStyle(GroupedListStyle())
        }
        
    }
}

#if DEBUG
struct FittingCargo_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        
        return FittingCargo(ship: gang.pilots[0].ship!)
            .environmentObject(gang)
            .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
