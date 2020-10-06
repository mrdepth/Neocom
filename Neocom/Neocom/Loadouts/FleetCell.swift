//
//  FleetCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/9/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct FleetCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @ObservedObject var fleet: Fleet
    
    private func cell(loadout: Loadout) -> some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == loadout.typeID).first()
        return type.map { type in
            Icon(type.image).cornerRadius(4)
        }
    }
    
    private func row(loadouts: [Loadout]) -> some View {
        HStack {
            ForEach(loadouts, id: \.objectID) { loadout in
                self.cell(loadout: loadout)
            }
        }
    }
    
    var body: some View {
        let loadouts = fleet.loadouts?.allObjects as? [Loadout] ?? []
        return VStack(alignment: .leading) {
            HStack {
                row(loadouts: Array(loadouts.prefix(5)))
                if loadouts.count > 5 {
                    Text("+\(loadouts.count - 5) more").modifier(SecondaryLabelModifier())
                }
            }
            Text(fleet.name ?? "").modifier(SecondaryLabelModifier())
        }
    }
}

struct FleetCell_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                FleetCell(fleet: Fleet.testFleet())
            }.listStyle(GroupedListStyle())
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
