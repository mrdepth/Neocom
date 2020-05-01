//
//  PowerGridResource.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct PowerGridResource: View {
    @ObservedObject var ship: DGMShip
    
    var body: some View {
        ShipResource(used: ship.usedPowerGrid, total: ship.totalPowerGrid, unit: .megaWatts, image: Image("powerGrid"), style: .progress)
    }
}

struct PowerGridResource_Previews: PreviewProvider {
    static var previews: some View {
        PowerGridResource(ship: DGMGang.testGang().pilots[0].ship!)
    }
}
