//
//  FittingEditorFirepowerStats.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorFirepowerStats: View {
    @ObservedObject var ship: DGMShip
    let formatter = UnitFormatter(unit: .none, style: .short)
    
    private func header(text: Text, image: Image) -> some View {
        HStack {
            Icon(image, size: .small)
            text
            }.frame(maxWidth: .infinity).offset(x: -16)
    }
    
    private func cell(_ damage: Double) -> some View {
        Text(formatter.string(from: damage)).fixedSize().frame(maxWidth: .infinity)
    }

    var body: some View {
        let weaponDPS = (ship.turretsDPS() + ship.launchersDPS()) * DGMSeconds(1)
        let dronesDPS = ship.dronesDPS() * DGMSeconds(1)
        let dps = weaponDPS + dronesDPS
        var total = dps.total
        if total <= 0 {
            total = 1
        }
        
        return Section(header: Text("FIREPOWER")) {
            VStack(spacing: 2) {
                HStack {
                    Color.clear.frame(maxWidth: .infinity)
                    header(text: Text("Weapons"), image: Image("turrets"))
                    header(text: Text("Drones"), image: Image("drone"))
                    header(text: Text("Total"), image: Image("dps"))
                }
                Divider()
                HStack {
                    Text("Volley").frame(maxWidth: .infinity)
                    cell(ship.turretsVolley.total + ship.launchersVolley.total)
                    cell(ship.dronesVolley.total)
                    cell(ship.turretsVolley.total + ship.launchersVolley.total + ship.dronesVolley.total)
                }
                Divider()
                HStack {
                    Text("DPS").frame(maxWidth: .infinity)
                    cell(weaponDPS.total)
                    cell(dronesDPS.total)
                    cell(dps.total)
                }
                Divider()
                HStack {
                    Icon(Image("damagePattern"), size: .small)
                    ResistanceView(ship: ship, resistance: dps.em / total, damageType: .em)
                    ResistanceView(ship: ship, resistance: dps.thermal / total, damageType: .thermal)
                    ResistanceView(ship: ship, resistance: dps.kinetic / total, damageType: .kinetic)
                    ResistanceView(ship: ship, resistance: dps.explosive / total, damageType: .explosive)
                }
            }.font(.caption)
            .lineLimit(1)
        }
    }
}

struct FittingEditorFirepowerStats_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return List {
            FittingEditorFirepowerStats(ship: gang.pilots.first!.ship!)
        }.listStyle(GroupedListStyle())
            .environmentObject(gang)
            .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}


