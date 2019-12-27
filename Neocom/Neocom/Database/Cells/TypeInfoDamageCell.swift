//
//  TypeInfoDamageCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/5/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData

extension TypeInfoData.Row {
    var damage: DamageRow? {
        switch self {
        case let .damage(damage):
            return damage
        default:
            return nil
        }
    }
}


struct TypeInfoDamageCell: View {
    var damage: Damage
    var percentStyle: Bool
    
    var body: some View {
        var damages = [damage.em, damage.thermal, damage.kinetic, damage.explosive]
        
        var total = damages.reduce(0, +)
        if total == 0 {
            total = 1
        }

        if percentStyle {
            damages = damages.map{$0 / total}
        }
        let damageTypes: [DamageType] = [.em, .thermal, .kinetic, .explosive]
        
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ForEach(0..<4) { i in
                    DamageView("\(Int(self.percentStyle ? (damages[i] * 100).rounded() : damages[i].rounded()))\(self.percentStyle ? "%" : "")",
                        percent: self.percentStyle ? damages[i] : damages[i] / total,
                        damageType: damageTypes[i])
                }
            }
        }.font(.footnote)
    }
}

struct TypeInfoDamageCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TypeInfoDamageCell(damage: Damage(em: 0.25, thermal: 0.25, kinetic: 0.25, explosive: 0.25), percentStyle: true)
            TypeInfoDamageCell(damage: Damage(em: 100, thermal: 100, kinetic: 100, explosive: 100), percentStyle: false)
        }.listStyle(GroupedListStyle())
    }
}
