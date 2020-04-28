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
    let priceData = Lazy<PricesData, Never>()

    var body: some View {
        let gang = project.gang
        let ship = project.structure ?? gang?.pilots.first?.ship
        
        return Group {
            if ship != nil {
                if ship is DGMStructure {
                    FittingStructureEditor(structure: ship as! DGMStructure)
                        .environmentObject(project)
                }
                else if gang != nil {
                    FittingShipEditor(gang: gang!, ship: ship!)
                        .environmentObject(project)
                }
            }
            else {
                Text(RuntimeError.invalidGang)
            }
        }
        .environmentObject(project)
        .environmentObject(priceData.get(initial: PricesData(esi: sharedState.esi)))
        .preference(key: AppendPreferenceKey<AnyUserActivityProvider, AnyUserActivityProvider>.self, value: [AnyUserActivityProvider(project)])
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
                FittingEditorShipActions()
                    .navigationBarItems(leading: BarButtonItems.close {
                        self.isActionsPresented = false
                    })
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .environmentObject(self.gang)
            .environmentObject(self.currentShip)
            .environmentObject(self.project)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Picker("Page", selection: $currentPage) {
                    Text("Modules").tag(Page.modules)
                    Text("Drones").tag(Page.drones)
                    Text("Implants").tag(Page.implants)
                    Text("Fleet").tag(Page.fleet)
                    Text("Cargo").tag(Page.cargo)
                    if horizontalSizeClass != .regular {
                        Text("Stats").tag(Page.stats)
                    }
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
            }
            if horizontalSizeClass == .regular {
                Divider().edgesIgnoringSafeArea(.bottom)
                FittingEditorStats()
            }
        }.navigationBarItems(trailing: actionsButton)
        .environmentObject(gang)
        .environmentObject(currentShip)
        .navigationBarTitle(Text(title), displayMode: .inline)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
                FittingEditorStructureActions()
                    .navigationBarItems(leading: BarButtonItems.close {
                        self.isActionsPresented = false
                    })
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .environmentObject(self.structure)
            .environmentObject(self.project)
            .navigationViewStyle(StackNavigationViewStyle())

        }
    }

    
    var body: some View {
        HStack(spacing: 1) {
            VStack(spacing: 0) {
                Picker("Page", selection: $currentPage) {
                    Text("Modules").tag(Page.modules)
                    Text("Fighters").tag(Page.drones)
                    if horizontalSizeClass != .regular {
                        Text("Stats").tag(Page.stats)
                    }
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
            }
            if horizontalSizeClass == .regular {
                FittingEditorStats()
            }
        }
        .navigationBarItems(trailing: actionsButton)
        .environmentObject(structure as DGMShip)
        .navigationBarTitle(Text(title), displayMode: .inline)
    }
}

struct FittingEditor_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditor(project: FittingProject(gang: gang, managedObjectContext: AppDelegate.sharedDelegate.persistentContainer.viewContext))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
