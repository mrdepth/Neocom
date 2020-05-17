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
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @State private var selectedProject: FittingProject?
    @State private var projectLoading: AnyPublisher<Result<FittingProject, Error>, Never>?
    @State private var openMode: OpenMode = .default
    @ObservedObject private var loadouts = Lazy<LoadoutsLoader, Never>()
    
    private func onSelect(_ type: SDEInvType, _ openMode: OpenMode) {
        let typeID = DGMTypeID(type.typeID)
        projectLoading = DGMSkillLevels.load(sharedState.account, managedObjectContext: managedObjectContext)
            .receive(on: RunLoop.main)
            .tryMap { try FittingProject(ship: typeID, skillLevels: $0, managedObjectContext: self.managedObjectContext) }
            .asResult()
            .eraseToAnyPublisher()
    }

    private func onSelect(_ loadout: Loadout, _ openMode: OpenMode) {
        self.openMode = openMode
        projectLoading = DGMSkillLevels.load(sharedState.account, managedObjectContext: managedObjectContext)
            .receive(on: RunLoop.main)
            .tryMap { try FittingProject(loadout: loadout, skillLevels: $0, managedObjectContext: self.managedObjectContext) }
            .asResult()
            .eraseToAnyPublisher()
    }
    
    private func onSelect(_ result: LoadoutsList.Result, _ openMode: OpenMode) {
        switch result {
        case let .type(type):
            onSelect(type, openMode)
        case let .loadout(objectID):
            onSelect(managedObjectContext.object(with: objectID) as! Loadout, openMode)
        }
    }
    
    var body: some View {
        let loadouts = self.loadouts.get(initial: LoadoutsLoader(.ship, managedObjectContext: managedObjectContext))
        return LoadoutsList(loadouts: loadouts, category: .ship, onSelect: onSelect)
            .onReceive(projectLoading ?? Empty().eraseToAnyPublisher()) { result in
                self.projectLoading = nil
                guard let project = result.value else {return}
                if UIApplication.shared.supportsMultipleScenes && self.openMode.openInNewWindow {
                    guard let activity = project.userActivity else {return}
                    project.updateUserActivityState(activity)
                    UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
                }
                else {
                    self.selectedProject = project
                }
        }
        .overlay(self.projectLoading != nil ? ActivityIndicator() : nil)
        .overlay(selectedProject.map{NavigationLink(destination: FittingEditor(project: $0), tag: $0, selection: $selectedProject, label: {EmptyView()})})
        .navigationBarTitle(Text("Loadouts"))
    }
}

#if DEBUG
struct ShipLoadouts_Previews: PreviewProvider {
    static var previews: some View {
        _ = Loadout.testLoadouts()
        return NavigationView {
            ShipLoadouts()
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
#endif
