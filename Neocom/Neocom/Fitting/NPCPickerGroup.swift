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
    
    private func groups() -> FetchedResultsController<SDENpcGroup> {
        let controller = managedObjectContext.from(SDENpcGroup.self)
            .filter(/\SDENpcGroup.parentNpcGroup == parent)
            .sort(by: \SDENpcGroup.npcGroupName, ascending: true)
            .fetchedResultsController()
        return FetchedResultsController(controller)
    }

    var body: some View {
        ObservedObjectView(groups()) { groups in
            TypesSearch(predicate: (/\SDEInvType.group?.npcGroups).count > 0) { searchResults in
                List {
                    if searchResults == nil {
                        NPCPickerGroupContent(groups: groups, completion: self.completion)
                    }
                    else {
                        TypePickerTypesContent(types: searchResults!, selectedType: self.$selectedType, completion: self.completion)
                    }
                }.listStyle(GroupedListStyle())
                    .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }
        }.navigationBarTitle(parent?.npcGroupName ?? NSLocalizedString("NPC", comment: ""))
        .sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }.modifier(ServicesViewModifier(environment: self.environment))
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
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
    }
}
