//
//  FittingEditorShipModulesList.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

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
    

    @State private var selectedSlot: SelectedSlot?
    private let typePickerState = Cache<DGMModule.Slot, TypePickerState>()
    
    private func typePicker(_ selection: SelectedSlot) -> some View {
        let category = try? self.managedObjectContext.fetch(SDEDgmppItemCategory.category(slot: selection.slot)).first
        
        return category.map { category in
            NavigationView {
                TypePicker(category: category) { (type) in
                    do {
                        for i in selection.sockets {
                            let module = try DGMModule(typeID: DGMTypeID(type.typeID))
                            try self.ship.add(module, socket: i)
                        }
                    }
                    catch {
                    }
                    self.selectedSlot = nil
                }.navigationBarItems(leading: BarButtonItems.close {
                    self.selectedSlot = nil
                })
            }.modifier(ServicesViewModifier(environment: self.environment))
                .environmentObject(typePickerState[selection.slot, default: TypePickerState()])
        }
    }
    
    var body: some View {
        let slots: [DGMModule.Slot] = [.hi, .med, .low, .rig, .subsystem, .service, .mode]
        
        let availableSlots = slots.filter{ship.totalSlots($0) > 0}
        
        return List {
            ForEach(availableSlots, id: \.self) { slot in
                FittingEditorShipModulesSection(slot: slot, selectedSlot: self.$selectedSlot)
            }
        }.listStyle(GroupedListStyle())
            .sheet(item: $selectedSlot) { selection in
                self.typePicker(selection)
        }
    }
}

#if DEBUG
struct FittingEditorShipModulesList_Previews: PreviewProvider {
    static var previews: some View {
        FittingEditorShipModulesList()
            .environmentObject(DGMShip.testDominix())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
#endif
