//
//  FittingEditorCapacitorStats.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorCapacitorStats: View {
    @ObservedObject var ship: DGMShip
    
    var body: some View {
        let capCapacity = ship.capacitor.capacity
        let isCapStable = ship.capacitor.isStable
        let capState = isCapStable ? ship.capacitor.stableLevel : ship.capacitor.lastsTime
        let capRechargeTime = ship.capacitor.rechargeTime
        let delta = (ship.capacitor.recharge - ship.capacitor.use) * DGMSeconds(1)
        
        return Section(header: Text("CAPACITOR")) {
            HStack {
                HStack {
                    Icon(Image("capacitor"))
                    VStack(alignment: .leading) {
                        Text("Total:")
                        if isCapStable {
                            Text("Stable:")
                        }
                        else {
                            Text("Lasts:")
                        }
                    }
                    VStack(alignment: .leading) {
                        Text(UnitFormatter.localizedString(from: capCapacity, unit: .gigaJoule, style: .long))
                        if isCapStable {
                            Text(String(format:"%.1f%%", capState * 100))
                        }
                        else {
                            Text(TimeIntervalFormatter.localizedString(from: capState, precision: .seconds))
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    Icon(Image("recharge"))
                    VStack(alignment: .leading) {
                        Text("Recharge:")
                        Text("Delta:")
                    }
                    VStack(alignment: .leading) {
                        Text(TimeIntervalFormatter.localizedString(from: capRechargeTime, precision: .seconds))
                        Text(delta > 0 ? "+" : "") + Text(UnitFormatter.localizedString(from: delta, unit: .gigaJoulePerSecond, style: .long))
                    }.layoutPriority(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }.font(.caption)
            .lineLimit(1)
        }
    }
}

#if DEBUG
struct FittingEditorCapacitorStats_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return List {
            FittingEditorCapacitorStats(ship: gang.pilots.first!.ship!)
        }.listStyle(GroupedListStyle())
            .environmentObject(gang)
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
