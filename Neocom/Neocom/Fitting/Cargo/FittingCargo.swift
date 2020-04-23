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
    @EnvironmentObject private var ship: DGMShip
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.self) private var environment
    @Environment(\.typePicker) private var typePicker
    @EnvironmentObject private var sharedState: SharedState
    @State private var selection: Selection?
    
    enum Selection: Identifiable {
        
        var id: AnyHashable {
            switch self {
            case let .group(group):
                return group.id
            case let .cargo(cargo):
                return cargo
            }
        }
        
        case group(SDEDgmppItemGroup)
        case cargo(DGMCargo)
        
        var cargo: DGMCargo? {
            switch self {
            case let .cargo(cargo):
                return cargo
            default:
                return nil
            }
        }
        
        var group: SDEDgmppItemGroup? {
            switch self {
            case let .group(group):
                return group
            default:
                return nil
            }
        }
    }
    
    private func typePicker(_ group: SDEDgmppItemGroup) -> some View {
        typePicker.get(group, environment: environment, sharedState: sharedState) {
            self.selection = nil
            guard let type = $0 else {return}
            do {
                try self.ship.add(DGMCargo(typeID: DGMTypeID(type.typeID)))
            }
            catch {
            }
        }
    }
    
    private func cargoActions(_ cargo: DGMCargo) -> some View {
        NavigationView {
            FittingCargoActions(cargo: cargo) {
                self.selection = nil
            }
        }
        .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
        .environmentObject(ship)
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    struct Row {
        var type: SDEInvType?
        var cargo: DGMCargo
    }
    
    struct CargoSection {
        var category: SDEInvCategory?
        var rows: [Row]
    }
    
    var body: some View {
        let cargo = ship.cargo
        let invTypes = cargo.map{$0.typeID}.compactMap{try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32($0)).first()}
        let types = Dictionary(invTypes.map{($0.typeID, $0)}) {a, _ in a}

        let rows = cargo.map{Row(type: types[Int32($0.typeID)], cargo: $0)}
        
        let sections = Dictionary(grouping: rows) {$0.type?.group?.category}
            .sorted{($0.key?.categoryName ?? "") < ($1.key?.categoryName ?? "")}
            .map{(category, rows) in CargoSection(category: category, rows: rows.sorted{($0.type?.typeName ?? "", $0.cargo.hashValue) < ($1.type?.typeName ?? "", $1.cargo.hashValue)})}
        
        return VStack(spacing: 0) {
                FittingCargoHeader().padding(8)
                Divider()
                List {
                    ForEach(sections, id: \.category) { section in
                        Section(header: section.category?.categoryName.map{Text($0.uppercased())}) {
                            ForEach(section.rows, id: \.cargo) { row in
                                Button(action: {self.selection = .cargo(row.cargo)}) {
                                    FittingCargoCell(cargo: row.cargo)
                                }.buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    Section {
                        Button("Add Cargo") {
                            self.selection = (try? self.managedObjectContext.fetch(SDEDgmppItemGroup.rootGroup(categoryID: .cargo)).first).map{.group($0)}
                        }.frame(maxWidth: .infinity)
                    }
                }.listStyle(GroupedListStyle())
                    .sheet(item: $selection) { selection in
                        if selection.group != nil {
                            self.typePicker(selection.group!)
                        }
                        else if selection.cargo != nil {
                            self.cargoActions(selection.cargo!)
                        }
            }
        }

    }
}

struct FittingCargo_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        
        return FittingCargo()
            .environmentObject(gang)
            .environmentObject(gang.pilots[0].ship!)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environmentObject(SharedState.testState())
    }
}
