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
    @EnvironmentObject private var ship: DGMShip
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                PowerGridResource()
                CPUResource()
            }
            HStack {
                CalibrationResource()
                HStack {
                    TurretsResource().frame(maxWidth: .infinity, alignment: .leading)
                    LaunchersResource().frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxWidth: .infinity)
            }
        }
    }
}

#if DEBUG
struct FittingEditorShipModulesHeader_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return FittingEditorShipModulesHeader()
            .environmentObject(gang)
            .environmentObject(gang.pilots[0].ship!)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .background(Color(.systemBackground))
//            .colorScheme(.dark)
            
    }
}
#endif
