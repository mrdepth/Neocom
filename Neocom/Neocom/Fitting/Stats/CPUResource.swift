//
//  CPUResource.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct CPUResource: View {
    @EnvironmentObject private var ship: DGMShip
    
    var body: some View {
        ShipResource(used: ship.usedCPU, total: ship.totalCPU, unit: .teraflops, image: Image("cpu"), style: .progress)
    }
}

struct CPUResource_Previews: PreviewProvider {
    static var previews: some View {
        CPUResource().environmentObject(DGMGang.testGang().pilots[0].ship!)
    }
}
