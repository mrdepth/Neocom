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
    
    @State private var isTypePickerPresented = false
    @Environment(\.self) private var environment
    @Environment(\.typePicker) private var typePicker
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.managedObjectContext) var managedObjectContext
    @ObservedObject var ship: DGMShip
    
    var group: SDEDgmppItemGroup? {
        try? self.managedObjectContext.fetch(SDEDgmppItemGroup.rootGroup(categoryID: category, subcategory: slot, race: nil)).first
    }

    private func typePicker(_ group: SDEDgmppItemGroup) -> some View {
        typePicker.get(group, environment: environment, sharedState: sharedState) {
            self.isTypePickerPresented = false
            guard let type = $0 else {return}
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                do {
                    if self.category == .implant {
                        let implant = try DGMImplant(typeID: DGMTypeID(type.typeID))
                        try (self.ship.parent as? DGMCharacter)?.add(implant)
                    }
                    else {
                        let booster = try DGMBooster(typeID: DGMTypeID(type.typeID))
                        try (self.ship.parent as? DGMCharacter)?.add(booster)
                    }
                }
                catch {
                }
            }
        }
    }
    
    var slot: Int
    var category: SDEDgmppItemCategoryID
    var body: some View {
        Button(action: {self.isTypePickerPresented = true}) {
            HStack {
                if category == .implant {
                    Icon(Image("implant"))
                    Text("Implant Slot \(slot)")
                }
                else {
                    Icon(Image("booster"))
                    Text("Booster Slot \(slot)")
                }
                Spacer()
            }.contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .adaptivePopover(isPresented: $isTypePickerPresented, arrowEdge: .leading) {
            self.group.map{self.typePicker($0)}
        }
    }
}

struct FittingImplantSlot_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return List {
            FittingImplantSlot(ship: gang.pilots[0].ship!, slot: 1, category: .implant)
        }
        .environmentObject(gang)
    }
}
