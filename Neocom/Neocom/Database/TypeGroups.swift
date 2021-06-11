//
//  TypeGroups.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible

struct TypeGroups: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    var category: SDEInvCategory
    
    private func getGroups() -> FetchedResultsController<SDEInvGroup> {
        let controller = managedObjectContext.from(SDEInvGroup.self)
            .filter(/\SDEInvGroup.category == category)
            .sort(by: \SDEInvGroup.published, ascending: false)
            .sort(by: \SDEInvGroup.groupName, ascending: true)
            .fetchedResultsController(sectionName: /\SDEInvGroup.published)
        return FetchedResultsController(controller)
    }
    
    @StateObject private var groups = Lazy<FetchedResultsController<SDEInvGroup>, Never>()
    
    func section(_ section: FetchedResultsController<SDEInvGroup>.Section) -> some View {
        Section(header: section.name == "0" ? Text("UNPUBLISHED") : Text("PUBLISHED")) {
            ForEach(section.objects, id: \.objectID) { group in
                NavigationLink(destination: Types(.group(group))) {
                    GroupCell(group: group)
                }
            }
        }
    }

    var body: some View {
        let groups = self.groups.get(initial: getGroups())
        let predicate = /\SDEInvType.group?.category == self.category && /\SDEInvType.published == true
        
        return List {
            ForEach(groups.sections, id: \.name, content: section)
        }
        .listStyle(GroupedListStyle())
        .search { publisher in
            TypesSearchResults(publisher: publisher, predicate: predicate) { type in
                NavigationLink(destination: TypeInfo(type: type)) {
                    TypeCell(type: type)
                }
            }
        }
        .navigationBarTitle(category.categoryName ?? NSLocalizedString("Groups", comment: ""))
    }
}

#if DEBUG
struct TypeGroups_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TypeGroups(category: try! Storage.testStorage.persistentContainer.viewContext.from(SDEInvCategory.self).first()!)
        }.modifier(ServicesViewModifier.testModifier())
    }
}
#endif
