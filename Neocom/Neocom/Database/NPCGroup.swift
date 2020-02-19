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

    private func groups() -> FetchedResultsController<SDENpcGroup> {
        let controller = managedObjectContext.from(SDENpcGroup.self)
            .filter(Expressions.keyPath(\SDENpcGroup.parentNpcGroup) == parent)
            .sort(by: \SDENpcGroup.npcGroupName, ascending: true)
            .fetchedResultsController()
        return FetchedResultsController(controller)
    }

    var body: some View {
        ObservedObjectView(groups()) { groups in
			TypesSearch(predicate: Expressions.keyPath(\SDEInvType.group?.npcGroups).count > 0) { searchResults in
                List {
                    if searchResults == nil {
                        NPCGroupContent(groups: groups)
                    }
                    else {
                        TypesContent(types: searchResults!)
                    }
                }.listStyle(GroupedListStyle())
                    .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }
        }.navigationBarTitle(parent?.npcGroupName ?? NSLocalizedString("NPC", comment: ""))
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
			.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
