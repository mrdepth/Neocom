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
    
    var slot: Int
    var body: some View {
        HStack {
            Icon(Image("implant"))
            Text("Implant Slot \(slot)")
            Spacer()
        }.contentShape(Rectangle())
    }
}

struct FittingImplantSlot_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FittingImplantSlot(slot: 1)
        }
    }
}
