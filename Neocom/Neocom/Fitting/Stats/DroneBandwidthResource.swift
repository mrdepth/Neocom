//
//  DroneBandwidthResource.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct DroneBandwidthResource: View {
    @EnvironmentObject private var ship: DGMShip
    
    var body: some View {
        ShipResource(used: ship.usedDroneBandwidth, total: ship.totalDroneBandwidth, unit: .megaBitsPerSecond, image: Image("droneBandwidth"), style: .progress)
    }
}

struct DroneBandwidthResource_Previews: PreviewProvider {
    static var previews: some View {
        DroneBandwidthResource().environmentObject(DGMGang.testGang().pilots[0].ship!)
    }
}
