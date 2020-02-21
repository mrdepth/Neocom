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
    @EnvironmentObject var ship: DGMShip
    
    func progress(used: Double, total: Double, image: Image, unit: UnitFormatter.Unit) -> some View {
        HStack(spacing: 0) {
            Icon(image, size: .small)
            Text("\(UnitFormatter.localizedString(from: used, unit: unit, style: .short))/\(UnitFormatter.localizedString(from: total, unit: unit, style: .short))")
                .frame(maxWidth: .infinity)
                .background(ProgressView(progress: Float(total > 0 ? used / total : 0)))
                .accentColor(.skyBlueBackground)
        }
    }
    
    func counter(used: Int, total: Int, image: Image, unit: UnitFormatter.Unit) -> some View {
        HStack() {
            Icon(image, size: .small)
            Text("\(UnitFormatter.localizedString(from: used, unit: unit, style: .short))/\(UnitFormatter.localizedString(from: total, unit: unit, style: .short))")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
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
                    turrets
                    launchers
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
