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
    
    enum Source {
        case predicate(Predictable, String)
        case group(SDEInvGroup)
    }
    
    private let predicate: Predictable
    private let title: String
    
    init(_ source: Source) {
        switch source {
        case let .predicate(predicate, title):
            self.predicate = predicate
            self.title = title
        case let .group(group):
            predicate = \SDEInvType.group == group
            title = group.groupName ?? "\(group.groupID)"
        }
    }
    
    private func types() -> FetchedResultsController<SDEInvType> {
        let controller = managedObjectContext.from(SDEInvType.self)
            .filter(predicate)
            .sort(by: \SDEInvType.metaGroup?.metaGroupID, ascending: true)
            .sort(by: \SDEInvType.metaLevel, ascending: true)
            .sort(by: \SDEInvType.typeName, ascending: true)
            .fetchedResultsController(sectionName: (\SDEInvType.metaGroup?.metaGroupID))
        return FetchedResultsController(controller)

    }
    
    var body: some View {
        ObservedObjectView(self.types()) { types in
            TypesSearch(predicate: self.predicate) { searchResults in
                List {
                    TypesContent(types: searchResults ?? types.sections)

//                    if searchResults == nil {
//                        TypesContent(types: types.sections)
//                    }
//                    else {
//                        TypesContent(types: searchResults!)
//                    }
                }.listStyle(GroupedListStyle())
                    .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }
        }.navigationBarTitle(title)
    }
}

struct TypesContent: View {
    var types: [FetchedResultsController<SDEInvType>.Section]
    
    var body: some View {
        print(types.map {
            ($0.name, $0.objects.map{$0.typeName!})
        })
        return ForEach(types, id: \.name) { section in
            Section(header: Text(section.objects.first?.metaGroup?.metaGroupName?.uppercased() ?? "")) {
                ForEach(section.objects, id: \.objectID) { type in
                    NavigationLink(destination: TypeInfo(type: type)) {
                        TypeCell(type: type)
                    }
                }
            }
        }
    }
}

struct Types_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Types(.group((try? AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEInvType.self).filter(\SDEInvType.typeID == 645).first()?.group)!))
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
