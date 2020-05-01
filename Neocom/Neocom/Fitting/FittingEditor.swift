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
    var completion: (() -> Void)? = nil
    
    private let priceData = Lazy<PricesData, Never>()

    var body: some View {
        let gang = project.gang
        let ship = project.structure ?? gang?.pilots.first?.ship
        
        return Group {
            if ship != nil {
                if ship is DGMStructure {
                    FittingStructureEditor(structure: ship as! DGMStructure, completion: completion)
                        .environmentObject(project)
                }
                else if gang != nil {
                    FittingShipEditor(gang: gang!, ship: ship!, completion: completion)
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
        .onAppear {
            self.sharedState.userActivity = self.project.userActivity
            UIApplication.shared.userActivity = self.project.userActivity
            self.sharedState.userActivity?.becomeCurrent()
        }
        .onDisappear {
            self.sharedState.userActivity?.resignCurrent()
            UIApplication.shared.userActivity = nil
            self.sharedState.userActivity = nil
            if self.project.hasUnsavedChanges {
                self.project.save()
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var completion: (() -> Void)?
    
    init(gang: DGMGang, ship: DGMShip, completion: (() -> Void)?) {
        _gang = ObservedObject(initialValue: gang)
        _currentShip = State(initialValue: ship)
        self.completion = completion
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
                FittingEditorShipActions(ship: self.currentShip)
                    .navigationBarItems(leading: BarButtonItems.close {
                        self.isActionsPresented = false
                    })
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .environmentObject(self.gang)
            .environmentObject(self.project)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    
    var body: some View {
        let body = VStack(spacing: 0) {
            Divider().edgesIgnoringSafeArea(.horizontal)
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    Picker("Page", selection: $currentPage) {
                        Text("Modules").tag(Page.modules)
                        Text("Drones").tag(Page.drones)
                        Text("Implants").tag(Page.implants)
                        if horizontalSizeClass != .regular {
                            Text("Fleet").tag(Page.fleet)
                        }
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
                        FittingEditorShipModules(ship: currentShip)
                    }
                    else if currentPage == .drones {
                        FittingEditorShipDrones(ship: currentShip)
                    }
                    else if currentPage == .implants {
                        FittingEditorImplants(ship: currentShip)
                    }
                    else if currentPage == .fleet {
                        FittingEditorFleet(ship: $currentShip)
                    }
                    else if currentPage == .stats {
                        FittingEditorStats(ship: currentShip)
                    }
                    else if currentPage == .cargo {
                        FittingCargo(ship: currentShip)
                    }
                }
                if horizontalSizeClass == .regular {
                    Divider().edgesIgnoringSafeArea(.bottom)
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 1)
                        FittingEditorStats(ship: currentShip)
                    }
                }
            }
            if horizontalSizeClass == .regular {
                Divider().edgesIgnoringSafeArea(.horizontal)
                FittingEditorFleetBar(ship: $currentShip)
            }
        }
        .environmentObject(gang)
        
        return Group {
            if completion != nil {
                body.navigationBarItems(leading: BarButtonItems.close(completion!), trailing: actionsButton)
            }
            else {
                body.navigationBarItems(trailing: actionsButton)
            }
        }
        .navigationBarTitle(Text(title), displayMode: .inline)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

struct FittingStructureEditor: View {
    @ObservedObject var structure: DGMStructure
    var completion: (() -> Void)?

    @State private var currentPage = Page.modules
    @State private var isActionsPresented = false
    
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
                    FittingEditorShipModules(ship: structure)
                }
                else if currentPage == .drones {
                    FittingEditorShipDrones(ship: structure)
                }
                else if currentPage == .stats {
                    FittingEditorStats(ship: structure)
                }
            }
            if horizontalSizeClass == .regular {
                FittingEditorStats(ship: structure)
            }
        }
        .navigationBarItems(leading: completion.map{BarButtonItems.close($0)}, trailing: actionsButton)
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
