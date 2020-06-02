//
//  StructureLoadouts.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/10/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Combine
import CoreData

struct StructureLoadouts: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @State private var selectedProject: FittingProject?
    @ObservedObject private var loadouts = Lazy<LoadoutsLoader, Never>()

    private func onSelect(_ project: FittingProject, _ openMode: OpenMode) {
        if UIApplication.shared.supportsMultipleScenes && openMode.openInNewWindow {
            guard let activity = project.userActivity else {return}
            project.updateUserActivityState(activity)
            UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
        }
        else {
            selectedProject = project
        }
    }

    private func onSelect(_ type: SDEInvType, _ openMode: OpenMode) {
        let typeID = DGMTypeID(type.typeID)
        guard let project = try? FittingProject(ship: typeID, skillLevels: .level(0), managedObjectContext: self.managedObjectContext) else {return}
        onSelect(project, openMode)
        
    }

    private func onSelect(_ loadout: Loadout, _ openMode: OpenMode) {
        guard let project = try? FittingProject(loadout: loadout, skillLevels: .level(0), managedObjectContext: self.managedObjectContext) else {return}
        onSelect(project, openMode)
    }

    private func onSelect(_ loadout: Ship, _ openMode: OpenMode) {
        guard let project = try? FittingProject(loadout: loadout, skillLevels: .level(0), managedObjectContext: self.managedObjectContext) else {return}
        onSelect(project, openMode)
    }

    private func onSelect(_ result: LoadoutsList.Result, _ openMode: OpenMode) {
        switch result {
        case let .type(type):
            onSelect(type, openMode)
        case let .loadout(objectID):
            onSelect(managedObjectContext.object(with: objectID) as! Loadout, openMode)
        case let .ship(loadout):
            onSelect(loadout, openMode)
        }
    }
    
    var body: some View {
        let loadouts = self.loadouts.get(initial: LoadoutsLoader(.structure, managedObjectContext: backgroundManagedObjectContext))
        return LoadoutsList(loadouts: loadouts, category: .structure, onSelect: onSelect)
        .overlay(selectedProject.map{NavigationLink(destination: FittingEditor(project: $0), tag: $0, selection: $selectedProject, label: {EmptyView()})})
        .navigationBarTitle(Text("Loadouts"))
    }
}

#if DEBUG
struct StructureLoadouts_Previews: PreviewProvider {
    static var previews: some View {
        _ = Loadout.testLoadouts()
        return NavigationView {
            StructureLoadouts()
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
#endif
