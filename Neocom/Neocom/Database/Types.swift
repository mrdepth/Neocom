//
//  Types.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/27/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct Types: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    let predicate: Predictable
    
    private func types() -> FetchedResultsController<SDEInvType> {
        let controller = managedObjectContext.from(SDEInvType.self)
            .filter(predicate)
            .sort(by: \SDEInvType.metaGroup?.metaGroupID, ascending: true)
            .sort(by: \SDEInvType.metaLevel, ascending: true)
            .sort(by: \SDEInvType.typeName, ascending: true)
            .fetchedResultsController(sectionName: (\SDEInvType.metaGroup?.metaGroupName))
        return FetchedResultsController(controller)

    }
    
    var body: some View {
        FetchedResultsView(self.types()) { types in
            TypesSearch(predicate: self.predicate) { searchResults in
                List {
                    if searchResults == nil {
                        TypesContent(types: types.sections)
                    }
                    else {
                        TypesContent(types: searchResults!)
                    }
                }.listStyle(GroupedListStyle())
                    .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }
        }
    }
}

struct TypesContent: View {
    var types: [FetchedResultsController<SDEInvType>.Section]
    
    var body: some View {
        ForEach(types, id: \.name) { section in
            Section(header: Text(section.name.uppercased())) {
                ForEach(section.objects, id: \.objectID) { type in
                    TypeCell(type: type)
                }
            }
        }
    }
}

struct Types_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Types(predicate: \SDEInvType.group == (try! AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEInvType.self).filter(\SDEInvType.typeID == 645).first()?.group))
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
