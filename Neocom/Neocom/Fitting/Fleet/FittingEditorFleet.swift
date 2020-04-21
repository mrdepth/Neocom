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
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @EnvironmentObject private var gang: DGMGang
    @EnvironmentObject private var project: FittingProject
    @EnvironmentObject private var sharedState: SharedState
    @State private var isLoadoutPickerPresented = false

    var body: some View {
        List {
            Section(header: Text("FLEET")) {
                ForEach(gang.pilots, id:\.self) { pilot in
                    Button(action: {
                        guard let ship = pilot.ship else {return}
                        self.ship = ship
                    }) {
                        FleetPilotCell(pilot: pilot).contentShape(Rectangle())
                    }.buttonStyle(PlainButtonStyle())
                }
                Button("Add Pilot") {
                    self.isLoadoutPickerPresented = true
                }.frame(maxWidth: .infinity)
            }
        }.listStyle(GroupedListStyle())
            .sheet(isPresented: $isLoadoutPickerPresented) {
                NavigationView {
                    FittingEditorLoadoutPicker(project: self.project) {
                        self.isLoadoutPickerPresented = false
                    }.navigationBarItems(leading: BarButtonItems.close {
                        self.isLoadoutPickerPresented = false
                    })
                }.modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
        }
    }
}

struct FittingEditorFleet_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let project = FittingProject(gang: gang)
        
        return FittingEditorFleet(ship: .constant(gang.pilots[0].ship!))
            .environmentObject(gang)
            .environmentObject(gang.pilots[0].ship!)
            .environmentObject(project)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
