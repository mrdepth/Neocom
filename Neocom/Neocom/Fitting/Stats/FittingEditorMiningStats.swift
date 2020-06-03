//
//  FittingEditorMiningStats.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorMiningStats: View {
    @ObservedObject var ship: DGMShip
    let formatter = UnitFormatter(unit: .none, style: .short)
    
    private func header(text: Text, image: Image) -> some View {
        HStack {
            Icon(image, size: .small)
            text
            }.frame(maxWidth: .infinity).offset(x: -16)
    }
    
    private func cell(_ damage: Double) -> some View {
        Text(formatter.string(from: damage)).fixedSize().frame(maxWidth: .infinity)
    }

    var body: some View {
        let minerYield = ship.minerYield * DGMSeconds(1)
        let droneYield = ship.droneYield * DGMSeconds(1)
        let total = droneYield + minerYield

        return Group {
            if total > 0 {
                Section(header: Text("FIREPOWER")) {
                    VStack(spacing: 2) {
                        HStack {
                            Color.clear.frame(maxWidth: .infinity)
                            header(text: Text("Miners"), image: Image("miners"))
                            header(text: Text("Drones"), image: Image("drone"))
                            header(text: Text("Total"), image: Image("cargo"))
                        }
                        Divider()
                        HStack {
                            Text("m³/s").frame(maxWidth: .infinity)
                            cell(minerYield)
                            cell(droneYield)
                            cell(total)
                        }
                    }.font(.caption)
                    .lineLimit(1)
                }
            }
        }
    }
}

struct FittingEditorMiningStats_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return List {
            FittingEditorMiningStats(ship: gang.pilots.first!.ship!)
        }.listStyle(GroupedListStyle())
            .environmentObject(gang)
            .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}


