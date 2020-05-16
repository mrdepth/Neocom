//
//  NPCPickerGroup.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct NPCPickerGroup: View {
    var parent: SDENpcGroup?
    var completion: (SDEInvType) -> Void
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @State private var selectedType: SDEInvType?
    @EnvironmentObject private var sharedState: SharedState
    
    private func getGroups() -> FetchedResultsController<SDENpcGroup> {
        let controller = managedObjectContext.from(SDENpcGroup.self)
            .filter(/\SDENpcGroup.parentNpcGroup == parent)
            .sort(by: \SDENpcGroup.npcGroupName, ascending: true)
            .fetchedResultsController()
        return FetchedResultsController(controller)
    }

    private let groups = Lazy<FetchedResultsController<SDENpcGroup>, Never>()
    
    @State private var searchString: String = ""
    @State private var searchResults: [FetchedResultsController<SDEInvType>.Section]? = nil

    var body: some View {
        let groups = self.groups.get(initial: getGroups())
        let predicate = (/\SDEInvType.group?.npcGroups).count > 0
        
        return TypesSearch(predicate: predicate, searchString: $searchString, searchResults: $searchResults) {
            if self.searchResults != nil {
                TypePickerTypesContent(types: self.searchResults!, selectedType: self.$selectedType, completion: self.completion)
            }
            else {
                NPCPickerGroupContent(groups: groups, completion: self.completion)
            }
        }
        .navigationBarTitle(parent?.npcGroupName ?? NSLocalizedString("NPC", comment: ""))
        .sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct NPCPickerGroupContent: View {
    var groups: FetchedResultsController<SDENpcGroup>
    var completion: (SDEInvType) -> Void
    
    private func content(for group: SDENpcGroup) -> some View {
        HStack {
            Icon(group.image)
            Text(group.npcGroupName ?? "")
        }
    }
    
    private func row(for group: SDENpcGroup) -> some View {
        Group {
            if (group.supNpcGroups?.count ?? 0) > 0 {
                NavigationLink(destination: NPCPickerGroup(parent: group, completion: completion)) {
                    self.content(for: group)
                }
            }
            else {
                
                NavigationLink(destination: NPCPickerTypes(parent: group, completion: completion)) {
                    self.content(for: group)
                }
            }
        }
    }

    var body: some View {
        ForEach(groups.fetchedObjects, id: \.objectID) { group in
            self.row(for: group)
        }
    }
}

struct NPCPickerGroup_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NPCPickerGroup() { _ in }
        }
            .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
    }
}
