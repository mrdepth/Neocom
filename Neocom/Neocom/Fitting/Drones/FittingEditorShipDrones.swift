//
//  FittingEditorShipDrones.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/4/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorShipDrones: View {
    var body: some View {
        VStack(spacing: 4) {
            FittingEditorShipDronesHeader().padding(.horizontal, 8)
            FittingEditorShipDronesList()
        }
    }
}

struct FittingEditorShipDrones_Previews: PreviewProvider {
    static var previews: some View {
        FittingEditorShipDrones()
            .environmentObject(DGMShip.testDominix())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)

    }
}
