//
//  FittingEditorFleetBar.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible

struct FittingEditorFleetBar: View {
    @Binding var ship: DGMShip
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @EnvironmentObject private var gang: DGMGang
    @EnvironmentObject private var project: FittingProject
    @EnvironmentObject private var sharedState: SharedState
    @State private var isLoadoutPickerPresented = false
    
    private func onClose(_ pilot: DGMCharacter) {
        guard let i = gang.pilots.firstIndex(of: pilot), gang.pilots.count > 1 else {return}
        if pilot.ship == ship {
            if i > 0 {
                self.ship = gang.pilots[i - 1].ship!
            }
            else {
                self.ship = gang.pilots[i + 1].ship!
            }
        }
        self.project.remove(pilot)
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(gang.pilots, id:\.self) { pilot in
                Button(action: {
                    guard let ship = pilot.ship else {return}
                    self.ship = ship
                }) {
                    FleetBarCell(currentShip: self.ship, pilot: pilot) {
                        self.onClose(pilot)
                    }.contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
            }
            Button(action: {self.isLoadoutPickerPresented = true}) {
                Image(systemName: "plus").frame(width: 32, height: 32).padding(.horizontal)//.contentShape(Rectangle())
            }
            .layoutPriority(10)
            .adaptivePopover(isPresented: $isLoadoutPickerPresented, arrowEdge: .bottom) {
                NavigationView {
                    FittingEditorLoadoutPicker(project: self.project) {
                        self.isLoadoutPickerPresented = false
                    }.navigationBarItems(leading: BarButtonItems.close {
                        self.isLoadoutPickerPresented = false
                    })
                }
                .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
                .navigationViewStyle(StackNavigationViewStyle())
                .frame(idealWidth: 375, idealHeight: 375 * 2)
            }

        }
        .background(Color(.systemFill).edgesIgnoringSafeArea(.all))
    }
}

struct FittingEditorFleetBar_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let project = FittingProject(gang: gang, managedObjectContext: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        
        return FittingEditorFleetBar(ship: .constant(gang.pilots[0].ship!))
            .environmentObject(gang)
            .environmentObject(project)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
