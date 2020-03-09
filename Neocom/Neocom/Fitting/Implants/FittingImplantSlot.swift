//
//  FittingImplantSlot.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/9/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingImplantSlot: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var slot: Int

    @EnvironmentObject private var ship: DGMShip
    @State private var selectedCategory: SDEDgmppItemCategory?
    private let typePickerState = TypePickerState()
    @Environment(\.self) private var environment
    
    private func typePicker(_ category: SDEDgmppItemCategory) -> some View {
        NavigationView {
            TypePicker(category: category) { (type) in
                do {
                    let implant = try DGMImplant(typeID: DGMTypeID(type.typeID))
                    try (self.ship.parent as? DGMCharacter)?.add(implant)
                }
                catch {
                }
                self.selectedCategory = nil
            }.navigationBarItems(leading: BarButtonItems.close {
                self.selectedCategory = nil
            })
        }.modifier(ServicesViewModifier(environment: self.environment))
            .environmentObject(typePickerState)
    }
    
    var body: some View {
        Button (action: {self.selectedCategory = try? self.managedObjectContext.fetch(SDEDgmppItemCategory.category(categoryID: .implant, subcategory: self.slot, race: nil)).first}) {
            HStack {
                Icon(Image("implant"))
                Text("Implant Slot \(slot)")
                Spacer()
            }.contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
            .sheet(item: $selectedCategory) { category in
                self.typePicker(category)
        }
    }
}

struct FittingImplantSlot_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return List {
            FittingImplantSlot(slot: 1)
        }.listStyle(GroupedListStyle())
            .environmentObject(gang.pilots[0].ship!)
            .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
