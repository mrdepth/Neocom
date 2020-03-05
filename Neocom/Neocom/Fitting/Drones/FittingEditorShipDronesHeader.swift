//
//  FittingEditorShipDronesHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorShipDronesHeader: View {
    @EnvironmentObject private var ship: DGMShip
    
    var body: some View {
        let droneBandwidth = ShipResource(used: ship.usedDroneBandwidth, total: ship.totalDroneBandwidth, unit: .megaBitsPerSecond, image: Image("droneBandwidth"), style: .progress)
        let droneBay = ShipResource(used: ship.usedDroneBay, total: ship.totalDroneBay, unit: .cubicMeter, image: Image("droneCapacity"), style: .progress)
        let dronesCount = ShipResource(used: ship.usedDroneSquadron(.none), total: ship.totalDroneSquadron(.none), unit: .none, image: Image("drone"), style: .counter)

        return HStack {
            droneBandwidth.frame(maxWidth: .infinity)
            droneBay.frame(maxWidth: .infinity)
            dronesCount
        }.font(.caption)
    }
}

struct FittingEditorShipDronesHeader_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        
        return FittingEditorShipDronesHeader()
            .environmentObject(gang)
            .environmentObject(gang.pilots[0].ship!)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .background(Color(.systemBackground))

    }
}
