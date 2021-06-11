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
    @ObservedObject var ship: DGMShip
    
    var body: some View {
        HStack {
            if ship.totalFighterLaunchTubes == 0 {
                DroneBandwidthResource(ship: ship)
            }
            DroneBayResource(ship: ship)
            DronesCountResource(ship: ship)
        }.font(.caption)
    }
}

#if DEBUG
struct FittingEditorShipDronesHeader_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        
        return FittingEditorShipDronesHeader(ship: gang.pilots[0].ship!)
            .environmentObject(gang)
            .modifier(ServicesViewModifier.testModifier())
            .background(Color(.systemBackground))

    }
}
#endif
