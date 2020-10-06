//
//  FittingEditorShipModulesHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorShipModulesHeader: View {
    @ObservedObject var ship: DGMShip
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                PowerGridResource(ship: ship)
                CPUResource(ship: ship)
            }
            HStack {
                CalibrationResource(ship: ship)
                HStack {
                    TurretsResource(ship: ship).frame(maxWidth: .infinity, alignment: .leading)
                    LaunchersResource(ship: ship).frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxWidth: .infinity)
            }
        }
    }
}

struct FittingEditorShipModulesHeader_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return FittingEditorShipModulesHeader(ship: gang.pilots[0].ship!)
            .modifier(ServicesViewModifier.testModifier())
            .background(Color(.systemBackground))
//            .colorScheme(.dark)
            
    }
}
