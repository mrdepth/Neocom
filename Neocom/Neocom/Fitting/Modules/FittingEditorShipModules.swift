//
//  FittingEditorShipModules.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorShipModules: View {
    @Environment(\.self) private var environment
    @ObservedObject var ship: DGMShip
    var body: some View {
        VStack(spacing: 0) {
            FittingEditorShipModulesHeader(ship: ship).padding(8)
            Divider()
            FittingEditorShipModulesList(ship: ship)
        }
    }
}

struct FittingEditorShipModules_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditorShipModules(ship: gang.pilots.first!.ship!)
        }
//        .environmentObject(DGMStructure.testKeepstar() as DGMShip)
        .environmentObject(gang)
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
