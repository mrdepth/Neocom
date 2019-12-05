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
    var damage: TypeInfoData.Row.DamageRow
    
    var body: some View {
        var damages = [damage.damage.em, damage.damage.thermal, damage.damage.kinetic, damage.damage.explosive]
        var total = damages.reduce(0, +)
        if total == 0 {
            total = 1
        }
        damages = damages.map{$0 / total}
        let damageTypes: [DamageType] = [.em, .thermal, .kinetic, .explosive]
        
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                ForEach(0..<4) { i in
                    DamageView(String(format: "%.0f%%", damages[i] * 100), percent: damages[i], damageType: damageTypes[i]).font(.footnote)
                }
            }
        }
    }
}

struct TypeInfoDamageCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            TypeInfoDamageCell(damage: TypeInfoData.Row.DamageRow(id: NSManagedObjectID(), damage: Damage(em: 0.25, thermal: 0.25, kinetic: 0.25, explosive: 0.25), percentStyle: true))
        }.listStyle(GroupedListStyle())
    }
}
