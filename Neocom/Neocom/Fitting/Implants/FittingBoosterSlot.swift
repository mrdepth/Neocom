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
    var slot: Int
    var body: some View {
        HStack {
            Icon(Image("booster"))
            Text("Booster Slot \(slot)")
            Spacer()
        }.contentShape(Rectangle())
    }
}

struct FittingBoosterSlot_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FittingBoosterSlot(slot: 1)
        }
    }
}
