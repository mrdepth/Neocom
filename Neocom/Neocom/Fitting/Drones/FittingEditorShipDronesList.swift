//
//  FittingEditorShipDronesList.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorShipDronesList: View {
    @EnvironmentObject private var ship: DGMShip
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment

    @State private var selectedCategory: SDEDgmppItemCategory?
    private let typePickerState = TypePickerState()

    private func typePicker(_ category: SDEDgmppItemCategory) -> some View {
        NavigationView {
            TypePicker(category: category) { (type) in
                do {
                    let tag = (self.ship.drones.compactMap({$0.squadron == .none ? $0.squadronTag : nil}).max() ?? -1) + 1
                    for _ in 0..<5 {
                        try self.ship.add(DGMDrone(typeID: DGMTypeID(type.typeID)), squadronTag: tag)
                    }
                }
                catch {
                    
                }
                self.selectedCategory = nil
            }.navigationBarItems(leading: BarButtonItems.close {
                self.selectedCategory = nil
            })
        }.modifier(ServicesViewModifier(environment: self.environment))
            .environmentObject(typePickerState)
    }

    
    private struct GroupingKey: Hashable {
        var squadronTag: Int
        var typeID: DGMTypeID
        var isActive: Bool
        var target: DGMShip?
    }
    
    var body: some View {
        let seq = ship.drones.filter{$0.squadron == .none}.map {
            (GroupingKey(squadronTag: $0.squadronTag, typeID: $0.typeID, isActive: $0.isActive, target: $0.target), $0)
        }
        let drones = Dictionary(grouping: seq) { $0.0 }//.values
            .mapValues{DGMDroneGroup($0.map{$0.1})}
            .sorted {$0.key.squadronTag < $1.key.squadronTag}
        
        return List {
            Section {
                ForEach(drones, id: \.key) { i in
                    FittingDroneCell(drone: i.value)
                }
            }
            Section {
                Button("Add Drone") {
                    self.selectedCategory = try? self.managedObjectContext.fetch(SDEDgmppItemCategory.category(categoryID: .drone)).first
                }.frame(maxWidth: .infinity)
            }
        }.listStyle(GroupedListStyle())
        .sheet(item: $selectedCategory) { category in
            self.typePicker(category)
        }
    }
}

struct FittingEditorShipDronesList_Previews: PreviewProvider {
    static var previews: some View {
        FittingEditorShipDronesList()
            .environmentObject(DGMShip.testDominix())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
