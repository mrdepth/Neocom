//
//  DroneBayResource.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct DroneBayResource: View {
    @ObservedObject var ship: DGMShip
    
    var body: some View {
        Group {
            if ship.totalFighterLaunchTubes > 0 {
                ShipResource(used: ship.usedFighterHangar, total: ship.totalFighterHangar, unit: .cubicMeter, image: Image("droneCapacity"), style: .progress)
            }
            else {
                ShipResource(used: ship.usedDroneBay, total: ship.totalDroneBay, unit: .cubicMeter, image: Image("droneCapacity"), style: .progress)
            }
        }
    }
}


struct DroneBayResource_Previews: PreviewProvider {
    static var previews: some View {
        DroneBayResource(ship: DGMGang.testGang().pilots[0].ship!)
    }
}
