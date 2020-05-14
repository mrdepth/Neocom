//
//  DamagePatternControl.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/18/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct DamagePatternControl: View {
    @Binding var damageVector: DGMDamageVector
    var body: some View {
        HStack {
            VStack(spacing: 8) {
                HorizontalSlider(value: $damageVector.em, max: damageVector.em + (1 - damageVector.total)).accentColor(Color.emDamage).frame(height: 30)
                    .overlay(Text("EM"))
                HorizontalSlider(value: $damageVector.thermal, max: damageVector.thermal + (1 - damageVector.total)).accentColor(Color.thermalDamage).frame(height: 30)
                .overlay(Text("Thermal"))
                HorizontalSlider(value: $damageVector.kinetic, max: damageVector.kinetic + (1 - damageVector.total)).accentColor(Color.kineticDamage).frame(height: 30)
                .overlay(Text("Kinetic"))
                HorizontalSlider(value: $damageVector.explosive, max: damageVector.explosive + (1 - damageVector.total)).accentColor(Color.explosiveDamage).frame(height: 30)
                .overlay(Text("Explosive"))
            }
            VStack(spacing: 8) {
                Text("\(Int(damageVector.em * 100))%").minimumScaleFactor(0.5).lineLimit(1).frame(height: 30)
                Text("\(Int(damageVector.thermal * 100))%").minimumScaleFactor(0.5).lineLimit(1).frame(height: 30)
                Text("\(Int(damageVector.kinetic * 100))%").minimumScaleFactor(0.5).lineLimit(1).frame(height: 30)
                Text("\(Int(damageVector.explosive * 100))%").minimumScaleFactor(0.5).lineLimit(1).frame(height: 30)
            }.frame(width: 50)
        }
    }
}

struct DamagePatternControl_Previews: PreviewProvider {
    static var previews: some View {
        DamagePatternControl(damageVector: .constant(.omni))
    }
}
