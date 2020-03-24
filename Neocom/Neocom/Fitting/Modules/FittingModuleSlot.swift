//
//  FittingModuleSlot.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingModuleSlot: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @EnvironmentObject private var typePickerState: TypePickerState
    @EnvironmentObject private var ship: DGMShip
    @State private var selectedCategory: SDEDgmppItemCategory?
    
    var slot: DGMModule.Slot
    var sockets: IndexSet
    
    private func typePicker(_ category: SDEDgmppItemCategory) -> some View {
        let category = try? self.managedObjectContext.fetch(SDEDgmppItemCategory.category(slot: slot, subcategory: Int(SDECategoryID.module.rawValue))).first
        
        return category.map { category in
            NavigationView {
                TypePicker(category: category) { (type) in
                    do {
                        for i in self.sockets {
                            let module = try DGMModule(typeID: DGMTypeID(type.typeID))
                            try self.ship.add(module, socket: i)
                        }
                    }
                    catch {
                    }
                    self.selectedCategory = nil
                }.navigationBarItems(leading: BarButtonItems.close {
                    self.selectedCategory = nil
                })
            }.modifier(ServicesViewModifier(environment: self.environment))
                .environmentObject(self.typePickerState)
        }
    }
    
    var body: some View {
        Button(action: {self.selectedCategory = try? self.managedObjectContext.fetch(SDEDgmppItemCategory.category(slot: self.slot, subcategory: Int(SDECategoryID.module.rawValue))).first}) {
            HStack {
                slot.image.map{Icon($0)}
                Text("Add Module")
                Spacer()
            }.contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
        .sheet(item: $selectedCategory) { category in
            self.typePicker(category)
        }
    }
}

struct FittingModuleSlot_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FittingModuleSlot(slot: .hi, sockets: IndexSet(integer: 0))
        }.listStyle(GroupedListStyle())
    }
}
