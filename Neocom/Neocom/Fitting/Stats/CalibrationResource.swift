//
//  CalibrationResource.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct CalibrationResource: View {
    @ObservedObject var ship: DGMShip
    
    var body: some View {
        ShipResource(used: ship.usedCalibration, total: ship.totalCalibration, unit: .none, image: Image("calibration"), style: .progress)
    }
}


struct CalibrationResource_Previews: PreviewProvider {
    static var previews: some View {
        CalibrationResource(ship: DGMGang.testGang().pilots[0].ship!)
    }
}
