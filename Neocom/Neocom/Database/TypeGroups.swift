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
    
    private let groups = Lazy<FetchedResultsController<SDEInvGroup>, Never>()
    
    @State private var searchString: String = ""
    @State private var searchResults: [FetchedResultsController<SDEInvType>.Section]? = nil

    var body: some View {
        let groups = self.groups.get(initial: getGroups())
        let predicate = /\SDEInvType.group?.category == self.category && /\SDEInvType.published == true
        
        return TypesSearch(predicate: predicate, searchString: $searchString, searchResults: $searchResults) {
            if self.searchResults != nil {
                TypesContent(types: self.searchResults!) { type in
                    NavigationLink(destination: TypeInfo(type: type)) {
                        TypeCell(type: type)
                    }
                }
            }
            else {
                TypeGroupsContent(groups: groups)
            }
        }
        .navigationBarTitle(category.categoryName ?? NSLocalizedString("Categories", comment: ""))
    }
}

struct TypeGroupsContent: View {
    var groups: FetchedResultsController<SDEInvGroup>
    
    var body: some View {
        ForEach(groups.sections, id: \.name) { section in
            Section(header: section.name == "0" ? Text("UNPUBLISHED") : Text("PUBLISHED")) {
                ForEach(section.objects, id: \.objectID) { group in
                    NavigationLink(destination: Types(.group(group))) {
                        GroupCell(group: group)
                    }
                }
            }
        }
    }
}

struct TypeGroups_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TypeGroups(category: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEInvCategory.self).first()!)
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
