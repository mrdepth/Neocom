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
    var body: some View {
        VStack(spacing: 4) {
            FittingEditorShipModulesHeader().padding(.horizontal, 8)
            FittingEditorShipModulesList()
        }
    }
}

#if DEBUG

struct FittingEditorShipModules_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditorShipModules()
        }
        .environmentObject(gang.pilots.first!.ship!)
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}

#endif
