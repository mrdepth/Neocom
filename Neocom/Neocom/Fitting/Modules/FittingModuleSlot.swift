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
    
    var slot: DGMModule.Slot
    
    var body: some View {
            HStack {
                slot.image.map{Icon($0)}
                Text("Add Module")
                Spacer()
            }.contentShape(Rectangle())
    }
}

struct FittingModuleSlot_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FittingModuleSlot(slot: .hi)
        }.listStyle(GroupedListStyle())
    }
}
