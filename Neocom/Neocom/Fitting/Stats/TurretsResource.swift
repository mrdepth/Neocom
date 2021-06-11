//
//  TurretsResource.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct TurretsResource: View {
    @ObservedObject var ship: DGMShip
    
    var body: some View {
        ShipResource(used: ship.usedHardpoints(.turret), total: ship.totalHardpoints(.turret), unit: .none, image: Image("turrets"), style: .counter)
    }
}

#if DEBUG
struct TurretsResource_Previews: PreviewProvider {
    static var previews: some View {
        TurretsResource(ship: DGMGang.testGang().pilots[0].ship!)
    }
}
#endif
