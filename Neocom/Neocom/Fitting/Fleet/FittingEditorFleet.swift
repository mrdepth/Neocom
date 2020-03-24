//
//  FittingEditorFleet.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/20/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible

struct FittingEditorFleet: View {
    @Binding var ship: DGMShip
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var gang: DGMGang

    var body: some View {
        List {
            ForEach(gang.pilots, id:\.self) { pilot in
                FleetPilotCell(pilot: pilot)
            }
        }.listStyle(GroupedListStyle())
    }
}

struct FittingEditorFleet_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        
        return FittingEditorFleet(ship: .constant(gang.pilots[0].ship!))
            .environmentObject(gang)
            .environmentObject(gang.pilots[0].ship!)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
