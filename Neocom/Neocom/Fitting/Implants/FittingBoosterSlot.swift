//
//  FittingBoosterSlot.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/9/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingBoosterSlot: View {
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
                    let booster = try DGMBooster(typeID: DGMTypeID(type.typeID))
                    try (self.ship.parent as? DGMCharacter)?.add(booster)
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
        Button (action: {self.selectedCategory = try? self.managedObjectContext.fetch(SDEDgmppItemCategory.category(categoryID: .booster, subcategory: self.slot, race: nil)).first}) {
            HStack {
                Icon(Image("booster"))
                Text("Booster Slot \(slot)")
                Spacer()
            }.contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
            .sheet(item: $selectedCategory) { category in
                self.typePicker(category)
        }
    }
}

struct FittingBoosterSlot_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return List {
            FittingBoosterSlot(slot: 1)
        }.listStyle(GroupedListStyle())
            .environmentObject(gang.pilots[0].ship!)
            .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
