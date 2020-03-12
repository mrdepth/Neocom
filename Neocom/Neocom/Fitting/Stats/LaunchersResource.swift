//
//  LaunchersResource.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct LaunchersResource: View {
    @EnvironmentObject private var ship: DGMShip
    
    var body: some View {
        ShipResource(used: ship.usedHardpoints(.launcher), total: ship.totalHardpoints(.launcher), unit: .none, image: Image("launchers"), style: .counter)
    }
}


struct LaunchersResource_Previews: PreviewProvider {
    static var previews: some View {
        LaunchersResource().environmentObject(DGMGang.testGang().pilots[0].ship!)
    }
}
