//
//  FittingEditorShipModulesHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorShipModulesHeader: View {
    @EnvironmentObject private var ship: DGMShip
    
    var body: some View {
        let powerGrid = ShipResource(used: ship.usedPowerGrid, total: ship.totalPowerGrid, unit: .megaWatts, image: Image("powerGrid"), style: .progress)
        let cpu = ShipResource(used: ship.usedCPU, total: ship.totalCPU, unit: .teraflops, image: Image("cpu"), style: .progress)
        let calibration = ShipResource(used: ship.usedCalibration, total: ship.totalCalibration, unit: .none, image: Image("calibration"), style: .progress)
        let turrets = ShipResource(used: ship.usedHardpoints(.turret), total: ship.totalHardpoints(.turret), unit: .none, image: Image("turrets"), style: .counter)
        let launchers = ShipResource(used: ship.usedHardpoints(.launcher), total: ship.totalHardpoints(.launcher), unit: .none, image: Image("launchers"), style: .counter)

        return VStack(spacing: 2) {
            HStack {
                powerGrid
                cpu
            }
            HStack {
                calibration
                HStack {
                    turrets.frame(maxWidth: .infinity, alignment: .leading)
                    launchers.frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxWidth: .infinity)
            }
        }.font(.caption)
    }
}

#if DEBUG
struct FittingEditorShipModulesHeader_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return FittingEditorShipModulesHeader()
            .environmentObject(gang)
            .environmentObject(gang.pilots[0].ship!)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .background(Color(.systemBackground))
//            .colorScheme(.dark)
            
    }
}
#endif
