//
//  ChargeTypeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/28/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct ChargeTypeCell: View {
    var charge: SDEDgmppItemDamage
    
    private func column(_ image: String, _ value: Float, _ unit: UnitFormatter.Unit) -> some View {
        return value > 0 ? HStack(spacing: 0) {
            Icon(Image(image), size: .small)
            Text("\(UnitFormatter.localizedString(from: value, unit: unit, style: .long))")
            } : nil
    }

    var body: some View {
        var damages = [charge.emAmount, charge.thermalAmount, charge.kineticAmount, charge.explosiveAmount]
        var total = damages.reduce(0, +)
        if total == 0 {
            total = 1
        }
        damages = damages.map{$0 / total}
        let damageTypes: [DamageType] = [.em, .thermal, .kinetic, .explosive]
        
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Icon(charge.item!.type!.image).cornerRadius(4)
                Text(charge.item?.type?.typeName ?? "")
            }
            HStack {
                ForEach(0..<4) { i in
                    DamageView(String(format: "%.0f%%", damages[i] * 100), percent: damages[i], damageType: damageTypes[i])
                }
            }
        }
    }
}

struct ChargeTypeCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ChargeTypeCell(charge: (try! AppDelegate.sharedDelegate.storageContainer.viewContext.from(SDEInvType.self).filter(\SDEInvType.dgmppItem?.damage != nil).first()?.dgmppItem?.damage)!)
        }.listStyle(GroupedListStyle())
    }
}
