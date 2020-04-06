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
    var project: FittingProject


    var body: some View {
        let ship = project.gang.pilots.first?.ship
        
        return Group {
            if ship != nil {
                FittingEditorBody(gang: project.gang, ship: ship!)
                    .environmentObject(project)
                    .onReceive(project.gang.objectWillChange) {
                        print("onReceive")
                }
            }
            else {
                Text(RuntimeError.invalidGang)
            }
        }
        .environmentObject(project)
        .onDisappear() {
            self.project.save(managedObjectContext: self.managedObjectContext)
//            self.context.save(managedObjectContext: self.managedObjectContext)
        }
    }
}

struct FittingEditorBody: View {
    enum Page: CaseIterable {
        case modules
        case drones
        case implants
        case fleet
        case stats
    }
    
    @State private var currentPage = Page.modules
    @State private var isActionsPresented = false
    @State private var currentShip: DGMShip
    @ObservedObject private var gang: DGMGang
    @Environment(\.self) private var environment
    @Environment(\.managedObjectContext) private var managedObjectContext
    
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
                FittingEditorActions().modifier(ServicesViewModifier(environment: self.environment))
                    .environmentObject(self.gang)
                    .environmentObject(self.currentShip)
                    .navigationBarItems(leading: BarButtonItems.close {
                        self.isActionsPresented = false
                    })
            }
        }
    }

    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Page", selection: $currentPage) {
                ForEach(Page.allCases, id: \.self) { page in
                    Text(String(describing: page).capitalized).tag(page)
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
        }.navigationBarItems(trailing: actionsButton)
        .environmentObject(gang)
        .environmentObject(currentShip)
        .navigationBarTitle(Text(title), displayMode: .inline)
    }
}

struct FittingEditor_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditor(project: FittingProject(gang: gang, loadouts: [:]))
        }
        .environmentObject(gang)
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environment(\.account, account)
        .environment(\.esi, esi)
    }
}
