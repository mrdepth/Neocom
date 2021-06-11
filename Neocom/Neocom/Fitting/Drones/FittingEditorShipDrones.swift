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
    @ObservedObject var ship: DGMShip
    @Environment(\.self) private var environment
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.typePicker) private var typePicker
    @EnvironmentObject private var sharedState: SharedState
    @State private var isTypePickerPresented = false
    
    private struct GroupingKey: Hashable {
        var squadron: DGMDrone.Squadron
        var squadronTag: Int
        var typeID: DGMTypeID
        var isActive: Bool
        var target: DGMShip?
    }

    private func typePicker(_ group: SDEDgmppItemGroup) -> some View {
        typePicker.get(group, environment: environment, sharedState: sharedState) {
            self.isTypePickerPresented = false
            guard let type = $0 else {return}
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                do {
                    let tag = (self.ship.drones.compactMap({$0.squadron == .none ? $0.squadronTag : nil}).max() ?? -2) + 1
                    let drone = try DGMDrone(typeID: DGMTypeID(type.typeID))
                    try self.ship.add(drone)
                    for _ in 1..<drone.squadronSize {
                        try self.ship.add(DGMDrone(typeID: DGMTypeID(type.typeID)), squadronTag: tag)
                    }
                }
                catch {
                    
                }
            }
        }
    }
    
    private func section(squadron: DGMDrone.Squadron, drones: [(key: GroupingKey, value: DGMDroneGroup)]) -> some View {
        let used = ship.usedDroneSquadron(squadron)
        let total = ship.totalDroneSquadron(squadron)
        
        let drones = ForEach(drones, id: \.key) { i in
//            Button(action: {self.selection = .drone(i.value)}) {
            FittingDroneCell(drone: i.value)
//            }.buttonStyle(PlainButtonStyle())
        }
        
        let title = squadron != .none ? Text("\(squadron.title.uppercased()) \(used)/\(total)") : nil
        
        return Section(header: title) {
            drones
        }
    }

    private var group: SDEDgmppItemGroup? {
        let isStructure = ship is DGMStructure
        
        if ship.totalFighterLaunchTubes > 0 {
            return try? self.managedObjectContext.fetch(SDEDgmppItemGroup.rootGroup(categoryID: isStructure ? .structureFighter : .fighter)).first
        }
        else {
            return try? self.managedObjectContext.fetch(SDEDgmppItemGroup.rootGroup(categoryID: .drone)).first
        }
    }
    
    var body: some View {
        let seq = ship.drones
//            .filter{$0.squadron == .none}
            .map {
                (GroupingKey(squadron: $0.squadron, squadronTag: $0.squadronTag, typeID: $0.typeID, isActive: $0.isActive, target: $0.target), $0)
        }
        
        let isStructure = ship is DGMStructure
        
        
        var sections = Dictionary(grouping: seq){$0.0.squadron}.mapValues { values in
            Dictionary(grouping: values) { $0.0 }//.values
                .mapValues{DGMDroneGroup($0.map{$0.1})}
                .sorted {$0.key.squadronTag < $1.key.squadronTag}
        }
        if ship.totalFighterLaunchTubes > 0 {
            let squadrons: Set<DGMDrone.Squadron> = Set(isStructure ?
                [.standupHeavy, .standupLight, .standupSupport] :
                [.heavy, .light, .support])
                .subtracting(sections.keys)
            squadrons.forEach{sections[$0] = []}
        }
        
        return VStack(spacing: 0) {
            FittingEditorShipDronesHeader(ship: ship).padding(8)
            Divider()
            List {
                ForEach(sections.sorted {$0.key.rawValue < $1.key.rawValue}, id: \.key) { section in
                    self.section(squadron: section.key, drones: section.value)
                }
                Section {
                    Button(ship.totalFighterLaunchTubes > 0 ? "Add Fighter" : "Add Drone") {
                        self.isTypePickerPresented = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .adaptivePopover(isPresented: $isTypePickerPresented, arrowEdge: .leading) {
                        self.group.map{self.typePicker($0)}
                    }
                }
            }.listStyle(GroupedListStyle())
        }
    }
}

#if DEBUG
struct FittingEditorShipDrones_Previews: PreviewProvider {
    static var previews: some View {
        FittingEditorShipDrones(ship: DGMShip.testNyx())
            .modifier(ServicesViewModifier.testModifier())

    }
}
#endif
