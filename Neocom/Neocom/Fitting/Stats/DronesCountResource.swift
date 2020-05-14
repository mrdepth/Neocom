//
//  DronesCountResource.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct DronesCountResource: View {
    @ObservedObject var ship: DGMShip
    
    var body: some View {
        Group {
            if ship.totalFighterLaunchTubes > 0 {
                ShipResource(used: ship.usedFighterLaunchTubes, total: ship.totalFighterLaunchTubes, unit: .none, image: Image("drone"), style: .counter)
            }
            else {
                ShipResource(used: ship.usedDroneSquadron(.none), total: ship.totalDroneSquadron(.none), unit: .none, image: Image("drone"), style: .counter)
            }
        }
    }
}

struct DronesCountResource_Previews: PreviewProvider {
    static var previews: some View {
        DronesCountResource(ship: DGMGang.testGang().pilots[0].ship!)
    }
}
