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

class FittingContext: ObservableObject {
    var gang: DGMGang?
    var loadouts: [DGMCharacter: Loadout] = [:]
    
    func save(managedObjectContext: NSManagedObjectContext) {
        gang?.pilots.forEach { pilot in
            guard let ship = pilot.ship else {return}
            
            
            let loadout: Loadout? = loadouts[pilot] ?? {
                let isEmpty = ship.modules.isEmpty && ship.drones.isEmpty
                
                if !isEmpty {
                    let loadout = Loadout(context: managedObjectContext)
                    loadout.data = LoadoutData(context: managedObjectContext)
                    loadout.typeID = Int32(ship.typeID)
                    loadout.uuid = UUID().uuidString
                    loadouts[pilot] = loadout
                    return loadout
                }
                else {
                    return nil
                }
            }()
            if let loadout = loadout {
                loadout.name = ship.name
                loadout.data?.data = pilot.loadout
            }
        }
    }
    
}

struct FittingEditor: View {
//    enum Input {
//        case gang(DGMGang)
//        case typeID(DGMTypeID)
//        case loadout(Loadout)
//    }
    
    @Environment(\.managedObjectContext) private var managedObjectContext
//    @Environment(\.account) private var account
//    @Environment(\.esi) private var esi
//    @ObservedObject private var gang = Lazy<DataLoader<DGMGang, Error>>()
    var project: FittingProject
    
    
/*    private func getGang() -> DataLoader<DGMGang, Error> {
        let publisher = Just(account).setFailureType(to: Error.self)
            .compactMap{$0}
            .flatMap {DGMSkillLevels.fromAccount($0, managedObjectContext: self.managedObjectContext).replaceError(with: .level(5)).setFailureType(to: Error.self)}
            .replaceEmpty(with: .level(5))
            .receive(on: RunLoop.main)
            .tryMap { levels -> DGMGang in
                switch self.input {
                case let .gang(gang):
                    gang.pilots.forEach{
                        $0.setSkillLevels(levels)
                    }
                    return gang
                case let .typeID(typeID):
                    let gang = try DGMGang()
                    let pilot = try DGMCharacter()
                    gang.add(pilot)
                    pilot.ship = try DGMShip(typeID: typeID)
                    pilot.setSkillLevels(levels)
                    return gang
                case let .loadout(loadout):
                    let gang = try DGMGang()
                    let pilot = try DGMCharacter()
                    gang.add(pilot)
                    pilot.ship = try DGMShip(typeID: DGMTypeID(loadout.typeID))
                    if let data = loadout.data?.data {
                        pilot.ship?.loadout = data
                    }
                    return gang
                }
            }
        
        return DataLoader(publisher)
    }*/
    
//    private var context = FittingContext()
    
//    init(_ input: Input) {
//        self.input = input
//    }

    var body: some View {
//        let result = self.gang.get(initial: getGang()).result
//        let gang = result?.value
//        let error = result?.error
//
//        let ship = gang?.pilots.first?.ship
//
//        context.gang = gang
//        context.loadouts = [:]
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
        }.onDisappear() {
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

    
    var body: some View {
        VStack {
            Picker("Page", selection: $currentPage) {
                ForEach(Page.allCases, id: \.self) { page in
                    Text(String(describing: page)).tag(page)
                }
            }.pickerStyle(SegmentedPickerStyle()).padding(.horizontal)
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
        }.navigationBarItems(trailing: BarButtonItems.actions {
            self.isActionsPresented = true
        })
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
        .environmentObject(gang)
        .environmentObject(currentShip)
        .navigationBarTitle(Text(title))
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
