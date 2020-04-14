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
    
    @Environment(\.account) private var account
    @Environment(\.esi) private var esi
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @State private var selectedProject: FittingProject?
    @State private var projectLoading: AnyPublisher<Result<FittingProject, Error>, Never>?
    @ObservedObject private var fittings = Lazy<FittingsLoader>()
    @State private var deleteSubscription: AnyPublisher<[Int], Never> = Empty().eraseToAnyPublisher()
    
    private func onSelect(_ fitting: ESI.Fittings.Element) {
        projectLoading = DGMSkillLevels.load(account, managedObjectContext: managedObjectContext).tryMap {
            try FittingProject(fitting: fitting, skillLevels: $0)
        }.asResult().receive(on: RunLoop.main).eraseToAnyPublisher()

    }

    var body: some View {
        let result = account.map {
            self.fittings.get(initial: FittingsLoader(esi: esi, characterID: $0.characterID, managedObjectContext: backgroundManagedObjectContext))
        }
        let sections = result?.fittings?.value
        let error = result?.fittings?.error
        return List {
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
                            guard let characerID = self.account?.characterID else {return}
                            let ids = indices.map{section.loadouts[$0].id}
                            self.deleteSubscription = Publishers.Sequence(sequence: ids).flatMap { id in
                                self.esi.characters.characterID(Int(characerID)).fittings().fittingID(id).delete()
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
        .onReceive(projectLoading ?? Empty().eraseToAnyPublisher()) { result in
            self.projectLoading = nil
            self.selectedProject = result.value
        }
        .overlay(self.projectLoading != nil ? ActivityIndicator() : nil)
        .overlay(selectedProject.map{NavigationLink(destination: FittingEditor(project: $0), tag: $0, selection: $selectedProject, label: {EmptyView()})})
        .navigationBarTitle("In-Game Loadouts")
        .onReceive(deleteSubscription) { ids in
            result?.delete(fittingIDs: Set(ids))
            self.deleteSubscription = Empty().eraseToAnyPublisher()
        }

    }
}

struct IngameLoadouts_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        return NavigationView {
            IngameLoadouts()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environment(\.account, account)
        .environment(\.esi, esi)
    }
}
