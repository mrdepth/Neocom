//
//  FittingEditorResistancesStats.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct ResistanceView: View {
    @EnvironmentObject private var ship: DGMShip
    var resistance: DGMPercent
    var damageType: DamageType
    
    var body: some View {
        Text(String("\(Int(resistance * 100))%"))
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: 18)
            .padding(.horizontal, 4)
            .background(ProgressView(progress: Float(resistance)))
            .background(Color(.black))
            .foregroundColor(.white)
            .accentColor(damageType.accentColor)
    }
}

struct ResistancesLayerView: View {
    var damage: DGMDamageVector
    var body: some View {
        Group {
            ResistanceView(resistance: damage.em, damageType: .em)
            ResistanceView(resistance: damage.thermal, damageType: .thermal)
            ResistanceView(resistance: damage.kinetic, damageType: .kinetic)
            ResistanceView(resistance: damage.explosive, damageType: .explosive)
        }
    }
}

struct FittingEditorResistancesStats: View {
    private enum HPColumn {}
    
    @EnvironmentObject private var ship: DGMShip
    @State private var hpColumnWidth: CGFloat?
    
    var body: some View {
        let resistances = ship.resistances
        let damagePattern = ship.damagePattern
        let hp = ship.hitPoints
        let ehp = ship.effectiveHitPoints
        let formatter = UnitFormatter(unit: .none, style: .short)
        
        return Section(header: Text("RESISTANCES")) {
            VStack(spacing: 2) {
                HStack {
                    Color.clear.frame(width: 16, height: 0)
                    Icon(Image("em"), size: .small).frame(maxWidth: .infinity)
                    Icon(Image("thermal"), size: .small).frame(maxWidth: .infinity)
                    Icon(Image("kinetic"), size: .small).frame(maxWidth: .infinity)
                    Icon(Image("explosion"), size: .small).frame(maxWidth: .infinity)
                    Text("HP").sizePreference(HPColumn.self).frame(width: hpColumnWidth)
                }
                HStack {
                    Icon(Image("shield"), size: .small)
                    ResistancesLayerView(damage: DGMDamageVector(resistances.shield))
                    Text("\(formatter.string(from: hp.shield))").sizePreference(HPColumn.self).frame(width: hpColumnWidth)
                }
                HStack {
                    Icon(Image("armor"), size: .small)
                    ResistancesLayerView(damage: DGMDamageVector(resistances.armor))
                    Text("\(formatter.string(from: hp.armor))").sizePreference(HPColumn.self).frame(width: hpColumnWidth)
                }
                HStack {
                    Icon(Image("hull"), size: .small)
                    ResistancesLayerView(damage: DGMDamageVector(resistances.hull))
                    Text("\(formatter.string(from: hp.hull))").sizePreference(HPColumn.self).frame(width: hpColumnWidth)
                }
                Divider()
                HStack {
                    Icon(Image("damagePattern"), size: .small)
                    ResistancesLayerView(damage: damagePattern)
                    Color.clear.frame(width: hpColumnWidth)
                }
                Divider()
                Text("EHP: \(UnitFormatter.localizedString(from: ehp.shield + ehp.armor + ehp.hull, unit: .none, style: .long))").frame(maxWidth: .infinity, alignment: .trailing)
            }.font(.caption)
                .lineLimit(1)
            .onSizeChange(HPColumn.self) {self.hpColumnWidth = $0.map{$0.width}.max()}
        }
    }
}

struct FittingEditorResistancesStats_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return List {
            FittingEditorResistancesStats()
        }.listStyle(GroupedListStyle())
        .environmentObject(gang.pilots.first!.ship!)
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
