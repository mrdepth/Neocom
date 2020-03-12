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
    @EnvironmentObject private var ship: DGMShip
    
    var body: some View {
        ShipResource(used: ship.usedHardpoints(.turret), total: ship.totalHardpoints(.turret), unit: .none, image: Image("turrets"), style: .counter)
    }
}

struct TurretsResource_Previews: PreviewProvider {
    static var previews: some View {
        TurretsResource().environmentObject(DGMGang.testGang().pilots[0].ship!)
    }
}
