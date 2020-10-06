//
//  FittingEditorStats.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import EVEAPI

struct FittingEditorStats: View {
    @ObservedObject var ship: DGMShip
    var body: some View {
        List {
            FittingEditorResourcesStats(ship: ship)
            FittingEditorResistancesStats(ship: ship)
            FittingEditorCapacitorStats(ship: ship)
            FittingEditorTankStats(ship: ship)
            FittingEditorFirepowerStats(ship: ship)
            FittingEditorMiningStats(ship: ship)
            FittingEditorFuelStats(ship: ship)
            FittingEditorMiscStats(ship: ship)
            FittingEditorPriceStats(ship: ship)
        }.listStyle(GroupedListStyle())
    }
}

struct FittingEditorStats_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditorStats(ship: gang.pilots.first!.ship!)
        }
        .environmentObject(PricesData(esi: ESI()))
        .environmentObject(DGMStructure.testKeepstar() as DGMShip)
        .environmentObject(gang)
        .modifier(ServicesViewModifier.testModifier())
    }
}
