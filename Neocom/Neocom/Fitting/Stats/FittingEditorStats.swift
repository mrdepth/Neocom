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
    var body: some View {
        List {
            FittingEditorResourcesStats()
            FittingEditorResistancesStats()
            FittingEditorCapacitorStats()
            FittingEditorTankStats()
            FittingEditorFirepowerStats()
            FittingEditorMiningStats()
            FittingEditorFuelStats()
            FittingEditorMiscStats()
            FittingEditorPriceStats()
        }.listStyle(GroupedListStyle())
    }
}

struct FittingEditorStats_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditorStats()
        }
        .environmentObject(PricesData(esi: ESI()))
        .environmentObject(DGMStructure.testKeepstar() as DGMShip)
//        .environmentObject(gang.pilots.first!.ship!)
//        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
