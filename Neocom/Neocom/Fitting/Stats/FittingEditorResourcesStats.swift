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
    @EnvironmentObject private var ship: DGMShip
    
    var body: some View {
        Section(header: Text("RESOURCES")) {
            VStack(spacing: 4) {
                HStack {
                    TurretsResource().frame(maxWidth: .infinity)
                    LaunchersResource().frame(maxWidth: .infinity)
                    ShipResource(used: ship.usedCalibration, total: ship.totalCalibration, unit: .none, image: Image("calibration"), style: .counter).frame(maxWidth: .infinity)
                    DronesCountResource().frame(maxWidth: .infinity)
                }
                Divider()
                HStack {
                    CPUResource()
                    DroneBayResource()
                }
                HStack {
                    PowerGridResource()
                    DroneBandwidthResource()
                }
            }.lineLimit(1)
        }
    }
}

struct FittingEditorResourcesStats_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return List {
            FittingEditorResourcesStats()
        }.listStyle(GroupedListStyle())
        .environmentObject(gang.pilots.first!.ship!)
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
