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
    @ObservedObject var ship: DGMShip
    
    var body: some View {
        ShipResource(used: ship.usedDroneBandwidth, total: ship.totalDroneBandwidth, unit: .megaBitsPerSecond, image: Image("droneBandwidth"), style: .progress)
    }
}

#if DEBUG
struct DroneBandwidthResource_Previews: PreviewProvider {
    static var previews: some View {
        DroneBandwidthResource(ship: DGMGang.testGang().pilots[0].ship!)
    }
}
#endif
