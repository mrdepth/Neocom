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
        HStack {
            DroneBandwidthResource()
            DroneBayResource()
            DronesCountResource()
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
