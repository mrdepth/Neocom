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

struct ShipLoadouts: View {
//    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Loadout.typeID, ascending: true)])
    @Environment(\.account) private var account
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @Environment(\.self) private var environment
    @ObservedObject private var loadouts = Lazy<LoadoutsLoader>()
    @State private var selectedCategory: SDEDgmppItemCategory?
    @State private var selectedProject: FittingProject?
    @State private var projectLoading: AnyPublisher<Result<FittingProject, Error>, Never>?
    
    private let typePickerState = TypePickerState()
    private func typePicker(_ category: SDEDgmppItemCategory) -> some View {
        NavigationView {
            TypePicker(category: category) { (type) in
                self.selectedCategory = nil
                self.onSelect(type)
            }.navigationBarItems(leading: BarButtonItems.close {
                self.selectedCategory = nil
            })
        }.modifier(ServicesViewModifier(environment: self.environment))
            .environmentObject(typePickerState)
    }
    
    private func onSelect(_ type: SDEInvType) {
        let typeID = DGMTypeID(type.typeID)
        projectLoading = DGMSkillLevels.load(account, managedObjectContext: managedObjectContext).tryMap {
            try FittingProject(ship: typeID, skillLevels: $0)
        }.asResult().receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    var body: some View {
        let sections = self.loadouts.get(initial: LoadoutsLoader(.ship, managedObjectContext: managedObjectContext)).loadouts ?? []
        
        return List {
            Section {
                Button(action: {self.selectedCategory = try? self.managedObjectContext.fetch(SDEDgmppItemCategory.category(categoryID: .ship, subcategory: nil, race: nil)).first}) {
                    HStack {
                        Icon(Image("fitting"))
                        Text("New Loadout")
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
            }
            ForEach(sections) { section in
                Section(header: section.title.map{Text($0.uppercased())} ?? Text("UNKNOWN")) {
                    ForEach(section.loadouts) { loadout in
                        LoadoutCell(typeID: loadout.typeID, name: loadout.name, loadoutID: loadout.objectID)
                    }.onDelete { (indices) in
                        indices.map{self.managedObjectContext.object(with: section.loadouts[$0].objectID)}.forEach {self.managedObjectContext.delete($0)}
                        if self.managedObjectContext.hasChanges {
                            try? self.managedObjectContext.save()
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
            .sheet(item: $selectedCategory) { category in
                self.typePicker(category)
        }
        .onReceive(projectLoading ?? Empty().eraseToAnyPublisher()) { result in
            self.projectLoading = nil
            self.selectedProject = result.value
        }
        .overlay(self.projectLoading != nil ? ActivityView() : nil)
        .overlay(selectedProject.map{NavigationLink(destination: FittingEditor(project: $0), tag: $0, selection: $selectedProject, label: {EmptyView()})})
//        .overlay(selectedType.map{NavigationLink(destination: FittingEditor(.typeID(DGMTypeID($0.typeID))), tag: $0, selection: $selectedType, label: {EmptyView()})})

    }
}

struct ShipLoadouts_Previews: PreviewProvider {
    static var previews: some View {
        try? AppDelegate.sharedDelegate.persistentContainer.viewContext.from(Loadout.self).delete()
        
        var loadout = Loadout(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        loadout.name = "Test Loadout"
        loadout.typeID = 645

        loadout = Loadout(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        loadout.name = "Test Loadout2"
        loadout.typeID = 645
        try? AppDelegate.sharedDelegate.persistentContainer.viewContext.save()
        return NavigationView {
            ShipLoadouts()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
    }
}
