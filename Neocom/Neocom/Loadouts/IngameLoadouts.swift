//
//  IngameLoadouts.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/6/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine
import EVEAPI

struct IngameLoadouts: View {
    
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @State private var selectedProject: FittingProject?
    @State private var projectLoading: AnyPublisher<Result<FittingProject, Error>, Never>?
    @ObservedObject private var fittings = Lazy<FittingsLoader, Account>()
    @State private var deleteSubscription: AnyPublisher<[Int], Never> = Empty().eraseToAnyPublisher()
    
    private func onSelect(_ fitting: ESI.Fittings.Element) {
        projectLoading = DGMSkillLevels.load(sharedState.account, managedObjectContext: managedObjectContext).tryMap {
            try FittingProject(fitting: fitting, skillLevels: $0)
        }.asResult().receive(on: RunLoop.main).eraseToAnyPublisher()

    }

    var body: some View {
        let result = sharedState.account.map {
            self.fittings.get($0, initial: FittingsLoader(esi: sharedState.esi, characterID: $0.characterID, managedObjectContext: backgroundManagedObjectContext))
        }
        let sections = result?.fittings?.value
        let error = result?.fittings?.error
        let list = List {
            if sections != nil {
                ForEach(sections!) { section in
                    Section(header: section.title.map{Text($0.uppercased())} ?? Text("UNKNOWN")) {
                        ForEach(section.loadouts) { loadout in
                            Button(action: {self.onSelect(loadout.fitting)}) {
                                HStack {
                                    LoadoutCell(typeID: loadout.fitting.shipTypeID, name: loadout.fitting.name)
                                    Spacer()
                                }.contentShape(Rectangle())
                            }.buttonStyle(PlainButtonStyle()).id(loadout.id)
                        }.onDelete { (indices) in
                            //ToDo: Delete request
                            guard let characerID = self.sharedState.account?.characterID else {return}
                            let ids = indices.map{section.loadouts[$0].id}
                            self.deleteSubscription = Publishers.Sequence(sequence: ids).flatMap { id in
                                self.sharedState.esi.characters.characterID(Int(characerID)).fittings().fittingID(id).delete()
                                    .map { _ in id }
                                    .catch {_ in Empty<Int, Never>()}
                            }
                            .collect()
                            .receive(on: RunLoop.main)
                            .eraseToAnyPublisher()
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
        .overlay(error.map{Text($0)})
        .overlay(sections?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)

        return Group {
            if result != nil {
                list.onRefresh(isRefreshing: Binding(result!, keyPath: \.isLoading)) {
                    result?.update(cachePolicy: .reloadIgnoringLocalCacheData)
                }
            }
            else {
                list
            }
        }
        .navigationBarTitle("In-Game Loadouts")
        .onReceive(projectLoading ?? Empty().eraseToAnyPublisher()) { result in
            self.projectLoading = nil
            self.selectedProject = result.value
        }
        .overlay(self.projectLoading != nil ? ActivityIndicator() : nil)
        .overlay(selectedProject.map{NavigationLink(destination: FittingEditor(project: $0), tag: $0, selection: $selectedProject, label: {EmptyView()})})
        .onReceive(deleteSubscription) { ids in
            result?.delete(fittingIDs: Set(ids))
            self.deleteSubscription = Empty().eraseToAnyPublisher()
        }

    }
}

struct IngameLoadouts_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IngameLoadouts()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
