//
//  DamageVectorView.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct DamageVectorView: View {
    var damage: DGMDamageVector
    var percentStyle: Bool = true
    var body: some View {
        var damages = [damage.em, damage.thermal, damage.kinetic, damage.explosive]//.map{Double($0)}
        var total = damages.reduce(0, +)
        if total == 0 {
            total = 1
        }
        if percentStyle {
            damages = damages.map{$0 / total}
        }

        let damageTypes: [DamageType] = [.em, .thermal, .kinetic, .explosive]

        return HStack {
            if percentStyle {
                ForEach(0..<4) { i in
                    DamageView(String(format: "%.0f%%", (damages[i] * 100).rounded()), percent: damages[i], damageType: damageTypes[i]).font(.caption)
                }
            }
            else {
                ForEach(0..<4) { i in
                    DamageView(String(format: "%.0f%", damages[i].rounded()), percent: damages[i] / total, damageType: damageTypes[i]).font(.caption)
                }
            }
        }
    }
}

struct DamageVectorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DamageVectorView(damage: .omni, percentStyle: true)
            DamageVectorView(damage: DGMDamageVector(em: 100, thermal: 200, kinetic: 300, explosive: 400), percentStyle: true)
            DamageVectorView(damage: DGMDamageVector(em: 100, thermal: 200, kinetic: 300, explosive: 400), percentStyle: false)
        }
    }
}
