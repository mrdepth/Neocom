//
//  Fleets.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/9/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine

struct Fleets: View {
    @EnvironmentObject private var sharedState: SharedState
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @State private var selectedProject: FittingProject?
    @State private var projectLoading: AnyPublisher<Result<FittingProject, Error>, Never>?
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Fleet.name, ascending: true)])
    private var fleets: FetchedResults<Fleet>
    
    private func onSelect(_ fleet: Fleet) {
        let configuration = fleet.configuration.flatMap{ try? JSONDecoder().decode(FleetConfiguration.self, from: $0) } ?? FleetConfiguration(pilots: [:], links: [:])
        let urls = configuration.pilots.values.compactMap{URL(string: $0)}
        
        projectLoading = Publishers.Sequence(sequence: urls)
            .setFailureType(to: Error.self)
            .flatMap { url in
                DGMSkillLevels.from(url: url, managedObjectContext: self.managedObjectContext)
                    .catch {_ in Empty()}
                    .map {(url, $0)}
        }
        .collect()
        .receive(on: RunLoop.main)
        .tryMap { skillLevels in
            try FittingProject(fleet: fleet, configuration: configuration, skillLevels: Dictionary(skillLevels) {a, _ in a})
        }.asResult().eraseToAnyPublisher()
    }

    var body: some View {
        return List {
            ForEach(fleets, id: \.objectID) { fleet in
                Button(action: {
                    self.onSelect(fleet)
                }) {
                    HStack {
                        FleetCell(fleet: fleet)
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
            }.onDelete { (indices) in
                indices.map{self.fleets[$0]}.forEach {self.managedObjectContext.delete($0)}
                if self.managedObjectContext.hasChanges {
                    try? self.managedObjectContext.save()
                }
            }
        }
        .listStyle(GroupedListStyle())
        .onReceive(projectLoading ?? Empty().eraseToAnyPublisher()) { result in
            self.projectLoading = nil
            self.selectedProject = result.value
        }
        .overlay(self.projectLoading != nil ? ActivityIndicator() : nil)
        .overlay(selectedProject.map{NavigationLink(destination: FittingEditor(project: $0), tag: $0, selection: $selectedProject, label: {EmptyView()})})
        .navigationBarTitle("Fleets")

        
    }
}

struct Fleets_Previews: PreviewProvider {
    static var previews: some View {
        _ = Fleet.testFleet()
        return NavigationView {
            Fleets()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
