//
//  TypePickerGroups.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/25/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible

struct TypePickerGroups: View {
    var parentGroup: SDEDgmppItemGroup
    var completion: (SDEInvType) -> Void
    @Binding var selectedGroup: SDEDgmppItemGroup?
    @State private var selectedType: SDEInvType?
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    
    private func groups() -> FetchedResultsController<SDEDgmppItemGroup> {
        let controller = managedObjectContext.from(SDEDgmppItemGroup.self)
            .filter(/\SDEDgmppItemGroup.parentGroup == parentGroup)
            .sort(by: \SDEDgmppItemGroup.groupName, ascending: true)
            .fetchedResultsController()
        
        return FetchedResultsController(controller)
    }
    
    private var predicate: PredicateProtocol {
        (/\SDEInvType.dgmppItem?.groups).any(\SDEDgmppItemGroup.category) == parentGroup.category && /\SDEInvType.published == true
    }
    
    var body: some View {
        ObservedObjectView(self.groups()) { groups in
            TypesSearch(searchString: "", predicate: self.predicate, onUpdated: nil) { searchResults in
                List {
                    if searchResults == nil {
                        ForEach(groups.fetchedObjects, id: \.objectID) { group in
                            NavigationLink(destination: TypePickerPage(parentGroup: group, completion: self.completion),
                                           tag: group,
                                           selection: self.$selectedGroup) {
                                            HStack {
                                                Icon(group.image)
                                                Text(group.groupName ?? "")
                                            }
                            }
                        }
                    }
                    else {
                        TypePickerTypesContent(types: searchResults!, selectedType: self.$selectedType, completion: self.completion)
                    }
                }.listStyle(GroupedListStyle())
                .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }
        }
        .navigationBarTitle(parentGroup.groupName ?? "")
        .sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct TypePickerGroups_Previews: PreviewProvider {
    static var previews: some View {
        let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
        let group = try! context.fetch(SDEDgmppItemGroup.rootGroup(categoryID: .hi)).first!
        return NavigationView {
            TypePickerGroups(parentGroup: group,
                             completion: {_ in },
                             selectedGroup: .constant(nil))
        }
        .environment(\.managedObjectContext, context)
    }
}
