//
//  ShipLoadouts.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/20/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Combine
import CoreData

struct ShipLoadouts: View {
    @Environment(\.account) private var account
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @State private var selectedProject: FittingProject?
    @State private var projectLoading: AnyPublisher<Result<FittingProject, Error>, Never>?
    private var loadouts = Lazy<LoadoutsLoader>()
    
    private func onSelect(_ type: SDEInvType) {
        let typeID = DGMTypeID(type.typeID)
        projectLoading = DGMSkillLevels.load(account, managedObjectContext: managedObjectContext).tryMap {
            try FittingProject(ship: typeID, skillLevels: $0)
        }.asResult().receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    private func onSelect(_ loadout: Loadout) {
        projectLoading = DGMSkillLevels.load(account, managedObjectContext: managedObjectContext)
            .receive(on: RunLoop.main)
            .tryMap {
                try FittingProject(loadout: loadout, skillLevels: $0)
        }.asResult().eraseToAnyPublisher()
    }
    
    private func onSelect(_ result: LoadoutsList.Result) {
        switch result {
        case let .type(type):
            onSelect(type)
        case let .loadout(objectID):
            onSelect(managedObjectContext.object(with: objectID) as! Loadout)
        }
    }
    
    var body: some View {
        let loadouts = self.loadouts.get(initial: LoadoutsLoader(.ship, managedObjectContext: backgroundManagedObjectContext))
        return LoadoutsList(loadouts: loadouts, onSelect: onSelect)
            .onReceive(projectLoading ?? Empty().eraseToAnyPublisher()) { result in
                self.projectLoading = nil
                self.selectedProject = result.value
        }
        .overlay(self.projectLoading != nil ? ActivityView() : nil)
        .overlay(selectedProject.map{NavigationLink(destination: FittingEditor(project: $0), tag: $0, selection: $selectedProject, label: {EmptyView()})})
        .navigationBarTitle("Loadouts")
    }
}

struct ShipLoadouts_Previews: PreviewProvider {
    static var previews: some View {
        _ = Loadout.testLoadouts()
        return NavigationView {
            ShipLoadouts()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
    }
}
