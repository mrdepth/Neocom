//
//  ShipCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/27/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct ShipTypeCell: View {
    var ship: SDEDgmppItemShipResources
    
    private func column(_ image: String, _ value: Int16) -> some View {
        return value > 0 ? HStack(spacing: 0) {
            Icon(Image(image), size: .small)
            Text("\(value)")
            } : nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Icon(ship.item!.type!.image).cornerRadius(4)
                Text(ship.item?.type?.typeName ?? "")
            }
            HStack(spacing: 15) {
                column("slotHigh", ship.hiSlots)
                column("slotMed", ship.medSlots)
                column("slotLow", ship.lowSlots)
                column("slotRig", ship.rigSlots)
                column("turrets", ship.turrets)
                column("launchers", ship.launchers)
            }.modifier(SecondaryLabelModifier())
        }
    }
}

struct ShipTypeCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ShipTypeCell(ship: SDEInvType.dominix.dgmppItem!.shipResources!)
        }.listStyle(GroupedListStyle())
    }
}
