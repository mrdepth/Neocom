//
//  FittingEditorLoadoutPicker.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorLoadoutPicker: View {
    var project: FittingProject
    var completion: () -> Void
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.managedObjectContext) private var managedObjectContext
    private let loadouts = Lazy<LoadoutsLoader, Never>()
    
    private func onSelect(_ result: LoadoutsList.Result) {
        do {
            let pilot = try DGMCharacter()
            switch result {
            case let .type(type):
                pilot.ship = try DGMShip(typeID: DGMTypeID(type.typeID))
                project.gang.add(pilot)
            case let .loadout(objectID):
                let loadout = managedObjectContext.object(with: objectID) as! Loadout
                pilot.ship = try DGMShip(typeID: DGMTypeID(loadout.typeID))
                pilot.ship?.name = loadout.name ?? ""
                
                if let loadout = loadout.ship {
                    pilot.loadout = loadout
                }
                
                if let ship = pilot.ship, !project.loadouts.values.contains(loadout) {
                    project.loadouts[ship] = loadout
                }
                project.gang.add(pilot)
            }
            completion()
        }
        catch {
        }
    }
    
    var body: some View {
        let loadouts = self.loadouts.get(initial: LoadoutsLoader(.ship, managedObjectContext: backgroundManagedObjectContext))
        return LoadoutsList(loadouts: loadouts, category: .ship, onSelect: onSelect)
    }
}

struct FittingEditorLoadoutPicker_Previews: PreviewProvider {
    static var previews: some View {
        _ = Loadout.testLoadouts()

        return NavigationView {
            FittingEditorLoadoutPicker(project: FittingProject(gang: DGMGang.testGang())) {}
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())

    }
}
