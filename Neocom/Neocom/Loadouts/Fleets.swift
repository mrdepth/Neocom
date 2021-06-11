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
    @State private var openMode: OpenMode = .default
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Fleet.name, ascending: true)])
    private var fleets: FetchedResults<Fleet>
    
    private func onSelect(_ fleet: Fleet, _ openMode: OpenMode) {
        let configuration = fleet.configuration.flatMap{ try? JSONDecoder().decode(FleetConfiguration.self, from: $0) } ?? FleetConfiguration(pilots: [:], links: [:])
        let urls = configuration.pilots.values.compactMap{URL(string: $0)}
        
        self.openMode = openMode
        projectLoading = Publishers.Sequence(sequence: urls)
//            .setFailureType(to: Error.self)
            .flatMap { url in
                DGMSkillLevels.from(url: url, managedObjectContext: self.managedObjectContext)
                    .catch {_ in Empty()}
                    .map {(url, $0)}
        }
        .collect()
        .receive(on: RunLoop.main)
        .tryMap { skillLevels in
            try FittingProject(fleet: fleet, configuration: configuration, skillLevels: Dictionary(skillLevels) {a, _ in a}, managedObjectContext: self.managedObjectContext)
        }.asResult().eraseToAnyPublisher()
    }

    var body: some View {
        return List {
            ForEach(fleets, id: \.objectID) { fleet in
                Button(action: {
                    self.onSelect(fleet, .default)
                }) {
                    HStack {
                        FleetCell(fleet: fleet)
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        if UIApplication.shared.supportsMultipleScenes {
                            Button(NSLocalizedString("Open in New Window", comment: "")) {
                                self.onSelect(fleet, .newWindow)
                            }
                            Button(NSLocalizedString("Open in Current Window", comment: "")) {
                                self.onSelect(fleet, .currentWindow)
                            }
                        }
                }

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
//        .overlay(selectedProject.map{NavigationLink(destination: FittingEditor(project: $0), tag: $0, selection: $selectedProject, label: {EmptyView()})})
        .navigationBarTitle(Text("Fleets"))
        .navigate(using: $selectedProject) { project in
            FittingEditor(project: project)
        }

        
    }
}

#if DEBUG
struct Fleets_Previews: PreviewProvider {
    static var previews: some View {
        _ = Fleet.testFleet()
        return NavigationView {
            Fleets()
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
