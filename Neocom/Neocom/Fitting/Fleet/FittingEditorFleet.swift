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
        let pilots = ForEach(gang.pilots, id:\.self) { pilot in
            Button(action: {
                guard let ship = pilot.ship else {return}
                self.ship = ship
            }) {
                FleetPilotCell(ship: self.$ship, pilot: pilot).contentShape(Rectangle())
            }.buttonStyle(PlainButtonStyle())
        }
        
        return List {
            Section(header: Text("FLEET")) {
                if gang.pilots.count > 1  {
                    pilots.onDelete { indices in
                        let pilots = self.gang.pilots
                        let toDelete = indices.map{pilots[$0]}
                        if let current = self.ship.parent as? DGMCharacter, let i = pilots.firstIndex(of: current), toDelete.contains(current) {
                            let left = IndexSet(pilots.indices).subtracting(indices)
                            if let j = left.min(by: {abs($0 - i) < abs($1 - i)}), let ship = pilots[j].ship {
                                self.ship = ship
                            }
                        }
                        
                        toDelete.forEach {
                            self.project.remove($0)
                        }
                    }
                }
                else {
                    pilots
                }
            }
            Section {
                Button(NSLocalizedString("Add Pilot", comment: "")) {
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
                }
                .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

#if DEBUG
struct FittingEditorFleet_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let project = FittingProject(gang: gang, managedObjectContext: Storage.testStorage.persistentContainer.viewContext)
        
        return FittingEditorFleet(ship: .constant(gang.pilots[0].ship!))
            .environmentObject(gang)
            .environmentObject(project)
            .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
