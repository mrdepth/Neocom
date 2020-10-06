//
//  FittingEditorResourcesStats.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorResourcesStats: View {
    @ObservedObject var ship: DGMShip
    
    var body: some View {
        Section(header: Text("RESOURCES")) {
            VStack(spacing: 4) {
                HStack {
                    TurretsResource(ship: ship).frame(maxWidth: .infinity)
                    LaunchersResource(ship: ship).frame(maxWidth: .infinity)
                    ShipResource(used: ship.usedCalibration, total: ship.totalCalibration, unit: .none, image: Image("calibration"), style: .counter).frame(maxWidth: .infinity)
                    DronesCountResource(ship: ship).frame(maxWidth: .infinity)
                }
                Divider()
                HStack {
                    CPUResource(ship: ship)
                    DroneBayResource(ship: ship)
                }
                HStack {
                    PowerGridResource(ship: ship)
                    DroneBandwidthResource(ship: ship)
                }
            }.lineLimit(1)
        }
    }
}

struct FittingEditorResourcesStats_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return List {
            FittingEditorResourcesStats(ship: gang.pilots.first!.ship!)
        }.listStyle(GroupedListStyle())
        .environmentObject(gang)
        .modifier(ServicesViewModifier.testModifier())
    }
}
