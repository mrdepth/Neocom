//
//  FittingCargoHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/17/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingCargoHeader: View {
    @ObservedObject var ship: DGMShip
    
    var body: some View {
        ShipResource(used: ship.usedCargoCapacity, total: ship.cargoCapacity, unit: .cubicMeter, image: Image("cargoBay"), style: .progress, format: .long)
            .font(.caption)
    }
}

#if DEBUG
struct FittingCargoHeader_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        
        return FittingCargoHeader(ship: gang.pilots[0].ship!)
            .environmentObject(gang)
            .modifier(ServicesViewModifier.testModifier())
            .background(Color(.systemBackground))

    }
}
#endif
