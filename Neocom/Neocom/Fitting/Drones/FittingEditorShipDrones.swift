//
//  FittingEditorShipDrones.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/4/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorShipDrones: View {
    enum Selection: Identifiable {
        
        var id: AnyHashable {
            switch self {
            case let .group(group):
                return group.id
            case let .drone(drone):
                return drone.id
            }
        }
        
        case group(SDEDgmppItemGroup)
        case drone(DGMDroneGroup)
        
        var drone: DGMDroneGroup? {
            switch self {
            case let .drone(drone):
                return drone
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
    
    @EnvironmentObject private var ship: DGMShip
    @Environment(\.self) private var environment
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.typePicker) private var typePicker
    @State private var selection: Selection?
    
    private struct GroupingKey: Hashable {
        var squadronTag: Int
        var typeID: DGMTypeID
        var isActive: Bool
        var target: DGMShip?
    }

    private func typePicker(_ group: SDEDgmppItemGroup) -> some View {
        typePicker.get(group, environment: environment) {
            self.selection = nil
            guard let type = $0 else {return}
            do {
                let tag = (self.ship.drones.compactMap({$0.squadron == .none ? $0.squadronTag : nil}).max() ?? -1) + 1
                for _ in 0..<5 {
                    try self.ship.add(DGMDrone(typeID: DGMTypeID(type.typeID)), squadronTag: tag)
                }
            }
            catch {
                
            }
        }
    }
    
    private func droneActions(_ drone: DGMDroneGroup) -> some View {
        NavigationView {
            FittingDroneActions(drone: drone) {
                self.selection = nil
            }
        }.modifier(ServicesViewModifier(environment: self.environment))
    }

    
    var body: some View {
        let seq = ship.drones.filter{$0.squadron == .none}.map {
            (GroupingKey(squadronTag: $0.squadronTag, typeID: $0.typeID, isActive: $0.isActive, target: $0.target), $0)
        }
        let drones = Dictionary(grouping: seq) { $0.0 }//.values
            .mapValues{DGMDroneGroup($0.map{$0.1})}
            .sorted {$0.key.squadronTag < $1.key.squadronTag}

        
        return VStack(spacing: 0) {
            FittingEditorShipDronesHeader().padding(8)
            Divider()
            List {
                Section {
                    ForEach(drones, id: \.key) { i in
                        Button(action: {self.selection = .drone(i.value)}) {
                            FittingDroneCell(drone: i.value)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
                Section {
                    Button("Add Drone") {
                        self.selection = (try? self.managedObjectContext.fetch(SDEDgmppItemGroup.rootGroup(categoryID: .drone)).first).map{.group($0)}
                    }.frame(maxWidth: .infinity)
                }
            }.listStyle(GroupedListStyle())
        }
        .sheet(item: $selection) { selection in
            if selection.group != nil {
                self.typePicker(selection.group!)
            }
            else if selection.drone != nil {
                self.droneActions(selection.drone!)
            }
        }

    }
}

struct FittingEditorShipDrones_Previews: PreviewProvider {
    static var previews: some View {
        FittingEditorShipDrones()
            .environmentObject(DGMShip.testDominix())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)

    }
}
