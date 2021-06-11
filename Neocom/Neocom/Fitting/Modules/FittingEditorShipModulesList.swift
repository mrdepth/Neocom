//
//  FittingEditorShipModulesList.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import CoreData

struct FittingEditorShipModulesList: View {
    @ObservedObject var ship: DGMShip
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment

    var body: some View {
        let slots: [DGMModule.Slot] = [.hi, .med, .low, .rig, .subsystem, .service, .mode]
        
        let availableSlots = slots.filter{ship.totalSlots($0) > 0}
        
        return List {
            ForEach(availableSlots, id: \.self) { slot in
                FittingEditorShipModulesSection(ship: self.ship, slot: slot)
            }
        }.listStyle(GroupedListStyle())
    }
}

#if DEBUG
struct FittingEditorShipModulesList_Previews: PreviewProvider {
    static var previews: some View {
        FittingEditorShipModulesList(ship: DGMShip.testDominix())
            .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
