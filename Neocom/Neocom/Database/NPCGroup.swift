//
//  NPCGroup.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.12.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct NPCGroup: View {
    var parent: SDENpcGroup?
    @Environment(\.managedObjectContext) var managedObjectContext

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
                TypesContent(types: self.searchResults!) { type in
                    NavigationLink(destination: TypeInfo(type: type)) {
                        TypeCell(type: type)
                    }
                }
            }
            else {
                NPCGroupContent(groups: groups)
            }
        }
        .navigationBarTitle(parent?.npcGroupName ?? NSLocalizedString("NPC", comment: ""))
    }
}

struct NPCGroupContent: View {
    var groups: FetchedResultsController<SDENpcGroup>
    
    private func content(for group: SDENpcGroup) -> some View {
        HStack {
            Icon(group.image)
            Text(group.npcGroupName ?? "")
        }
    }
    
    private func row(for group: SDENpcGroup) -> some View {
        Group {
            if (group.supNpcGroups?.count ?? 0) > 0 {
                NavigationLink(destination: NPCGroup(parent: group)) {
                    self.content(for: group)
                }
            }
            else {
                NavigationLink(destination: Types(.npc(group))) {
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

struct NPCGroup_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			NPCGroup()
		}
			.environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
