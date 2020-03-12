//
//  FittingEditorTankStats.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorTankStats: View {
    @EnvironmentObject private var ship: DGMShip
    let formatter = UnitFormatter(unit: .none, style: .short)
    
    private func cell(_ keyPath: KeyPath<DGMTank, DGMHPPerSecond>, tank: DGMTank, effectiveTank: DGMTank) -> some View {
        VStack {
            Text(formatter.string(from: tank[keyPath: keyPath] * DGMSeconds(1)))
            Text(formatter.string(from: effectiveTank[keyPath: keyPath] * DGMSeconds(1)))
        }.frame(maxWidth: .infinity)
    }
    
    private func row(tank: DGMTank, effectiveTank: DGMTank) -> some View {
        Group {
            cell(\.passiveShield, tank: tank, effectiveTank: effectiveTank)
            cell(\.shieldRepair, tank: tank, effectiveTank: effectiveTank)
            cell(\.armorRepair, tank: tank, effectiveTank: effectiveTank)
            cell(\.hullRepair, tank: tank, effectiveTank: effectiveTank)
        }
    }
    
    var body: some View {
        Section(header: Text("RECHARGE RATES (HP/S, EHP/S)")) {
            VStack(spacing: 2) {
                HStack {
                    Color.clear.frame(maxWidth: .infinity)
                    Icon(Image("shieldRecharge"), size: .small).frame(maxWidth: .infinity)
                    Icon(Image("shieldBooster"), size: .small).frame(maxWidth: .infinity)
                    Icon(Image("armorRepairer"), size: .small).frame(maxWidth: .infinity)
                    Icon(Image("hullRepairer"), size: .small).frame(maxWidth: .infinity)
                }
                Divider()
                HStack {
                    Text("Reinforced").frame(maxWidth: .infinity)
                    row(tank: ship.tank, effectiveTank: ship.effectiveTank)
                }
                Divider()
                HStack {
                    Text("Sustained").frame(maxWidth: .infinity)
                    row(tank: ship.sustainableTank, effectiveTank: ship.effectiveSustainableTank)
                }
            }.font(.caption)
            .lineLimit(1)
        }
    }
}

struct FittingEditorTankStats_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return List {
            FittingEditorTankStats()
        }.listStyle(GroupedListStyle())
            .environmentObject(gang.pilots.first!.ship!)
            .environmentObject(gang)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}


