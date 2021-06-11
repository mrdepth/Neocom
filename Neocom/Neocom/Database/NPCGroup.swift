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

    @StateObject private var groups = Lazy<FetchedResultsController<SDENpcGroup>, Never>()
    
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
        let groups = self.groups.get(initial: getGroups())
        let predicate = (/\SDEInvType.group?.npcGroups).count > 0
        
        return List {
            ForEach(groups.fetchedObjects, id: \.objectID, content: row)
        }
        .listStyle(GroupedListStyle())
        .search { publisher in
            TypesSearchResults(publisher: publisher, predicate: predicate) { type in
                NavigationLink(destination: TypeInfo(type: type)) {
                    TypeCell(type: type)
                }
            }
        }
        .navigationBarTitle(parent?.npcGroupName ?? NSLocalizedString("NPC", comment: ""))
    }
}

#if DEBUG
struct NPCGroup_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			NPCGroup()
		}
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
