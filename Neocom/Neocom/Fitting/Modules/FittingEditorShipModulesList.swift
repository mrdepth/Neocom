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
    struct SelectedSlot: Hashable, Identifiable {
        var slot: DGMModule.Slot
        var sockets: IndexSet
        var id: SelectedSlot {
            return self
        }
    }

    
    @EnvironmentObject private var ship: DGMShip
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    
    @Binding var selection: FittingEditorShipModules.Selection?
    
    var body: some View {
        let slots: [DGMModule.Slot] = [.hi, .med, .low, .rig, .subsystem, .service, .mode]
        
        let availableSlots = slots.filter{ship.totalSlots($0) > 0}
        
        return List {
            ForEach(availableSlots, id: \.self) { slot in
                FittingEditorShipModulesSection(slot: slot, selection: self.$selection)
            }
        }.listStyle(GroupedListStyle())
    }
}

struct FittingEditorShipModulesList_Previews: PreviewProvider {
    static var previews: some View {
        FittingEditorShipModulesList(selection: .constant(nil))
            .environmentObject(DGMShip.testDominix())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
