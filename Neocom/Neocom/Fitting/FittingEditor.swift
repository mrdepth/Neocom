//
//  FittingEditor.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import EVEAPI
import Combine
import CoreData

struct FittingEditor: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState
    var project: FittingProject
    @State private var isModified = false
    let priceData = Lazy<PricesData, Never>()

    var body: some View {
        let ship = project.structure ?? project.gang.pilots.first?.ship
        
        return Group {
            if ship != nil {
                if ship is DGMStructure {
                    FittingStructureEditor(structure: ship as! DGMStructure)
                        .environmentObject(project)
                        .onReceive(project.structure!.objectWillChange) {
                            self.isModified = true
                    }
                }
                else {
                    FittingShipEditor(gang: project.gang, ship: ship!)
                        .environmentObject(project)
                        .onReceive(project.gang.objectWillChange) {
                            self.isModified = true
                    }
                }
            }
            else {
                Text(RuntimeError.invalidGang)
            }
        }
        .environmentObject(project)
        .environmentObject(priceData.get(initial: PricesData(esi: sharedState.esi)))
        .onDisappear() {
            if self.isModified {
                self.project.save(managedObjectContext: self.managedObjectContext)
            }
        }
    }
}

fileprivate enum Page: CaseIterable {
    case modules
    case drones
    case implants
    case fleet
    case stats
    case cargo
}


struct FittingShipEditor: View {
    
    @State private var currentPage = Page.modules
    @State private var isActionsPresented = false
    @State private var currentShip: DGMShip
    @ObservedObject private var gang: DGMGang
    @Environment(\.self) private var environment
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var project: FittingProject
    @EnvironmentObject private var sharedState: SharedState
    
    init(gang: DGMGang, ship: DGMShip) {
        _gang = ObservedObject(initialValue: gang)
        _currentShip = State(initialValue: ship)
    }
    
    private var title: String {
        let typeName = currentShip.type(from: self.managedObjectContext)?.typeName ?? "Unknown"
        let name = currentShip.name
        if name.isEmpty {
            return typeName
        }
        else {
            return "\(typeName) / \(name)"
        }
    }
    
    private var actionsButton: some View {
        BarButtonItems.actions {
            self.isActionsPresented = true
        }
        .sheet(isPresented: $isActionsPresented) {
            NavigationView {
                FittingEditorShipActions().modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
                    .navigationBarItems(leading: BarButtonItems.close {
                        self.isActionsPresented = false
                    })
            }
            .environmentObject(self.gang)
            .environmentObject(self.currentShip)
            .environmentObject(self.project)
        }
    }

    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Page", selection: $currentPage) {
                Text("Modules").tag(Page.modules)
                Text("Drones").tag(Page.drones)
                Text("Implants").tag(Page.implants)
                Text("Fleet").tag(Page.fleet)
                Text("Cargo").tag(Page.cargo)
                Text("Stats").tag(Page.stats)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            Divider()
            if currentPage == .modules {
                FittingEditorShipModules()
            }
            else if currentPage == .drones {
                FittingEditorShipDrones()
            }
            else if currentPage == .implants {
                FittingEditorImplants()
            }
            else if currentPage == .fleet {
                FittingEditorFleet(ship: $currentShip)
            }
            else if currentPage == .stats {
                FittingEditorStats()
            }
            else if currentPage == .cargo {
                FittingCargo()
            }
        }.navigationBarItems(trailing: actionsButton)
        .environmentObject(gang)
        .environmentObject(currentShip)
        .navigationBarTitle(Text(title), displayMode: .inline)
    }
}

struct FittingStructureEditor: View {
    
    @State private var currentPage = Page.modules
    @State private var isActionsPresented = false
    @ObservedObject var structure: DGMStructure
    @Environment(\.self) private var environment
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var project: FittingProject
    @EnvironmentObject private var sharedState: SharedState
    
    private var title: String {
        let typeName = structure.type(from: self.managedObjectContext)?.typeName ?? "Unknown"
        let name = structure.name
        if name.isEmpty {
            return typeName
        }
        else {
            return "\(typeName) / \(name)"
        }
    }
    
    private var actionsButton: some View {
        BarButtonItems.actions {
            self.isActionsPresented = true
        }
        .sheet(isPresented: $isActionsPresented) {
            NavigationView {
                FittingEditorShipActions().modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
                    .navigationBarItems(leading: BarButtonItems.close {
                        self.isActionsPresented = false
                    })
            }
            .environmentObject(self.structure as DGMShip)
            .environmentObject(self.project)

        }
    }

    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Page", selection: $currentPage) {
                Text("Modules").tag(Page.modules)
                Text("Fighters").tag(Page.drones)
                Text("Stats").tag(Page.stats)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            Divider()
            if currentPage == .modules {
                FittingEditorShipModules()
            }
            else if currentPage == .drones {
                FittingEditorShipDrones()
            }
            else if currentPage == .stats {
                FittingEditorStats()
            }
        }.navigationBarItems(trailing: actionsButton)
        .environmentObject(structure as DGMShip)
        .navigationBarTitle(Text(title), displayMode: .inline)
    }
}

struct FittingEditor_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditor(project: FittingProject(gang: gang))
        }
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
