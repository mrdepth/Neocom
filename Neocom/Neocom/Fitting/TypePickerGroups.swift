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
    var category: SDEDgmppItemCategory
    var currentState: TypePickerState.Node
    var completion: (SDEInvType) -> Void
    @Binding var selectedGroup: SDEDgmppItemGroup?
    @State private var selectedType: SDEInvType?
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment

    private func groups() -> FetchedResultsController<SDEDgmppItemGroup> {
        let controller = managedObjectContext.from(SDEDgmppItemGroup.self)
            .filter(/\SDEDgmppItemGroup.parentGroup == currentState.parentGroup)
            .sort(by: \SDEDgmppItemGroup.groupName, ascending: true)
            .fetchedResultsController()
        
        return FetchedResultsController(controller)
    }
    
    private var predicate: PredicateProtocol {
        (/\SDEInvType.dgmppItem?.groups).any(\SDEDgmppItemGroup.category) == self.category && /\SDEInvType.published == true
    }
    
    var body: some View {
        
        return ObservedObjectView(self.groups()) { groups in
            TypesSearch(searchString: self.currentState.searchString ?? "", predicate: self.predicate, onUpdated: { self.currentState.searchString = $0 }) { searchResults in
                List {
                    if searchResults == nil {
                        ForEach(groups.fetchedObjects, id: \.objectID) { group in
                            NavigationLink(destination: TypePickerPage(category: self.category,
                                                                       currentState: (self.currentState.next?.parentGroup == group ? self.currentState.next : nil) ?? TypePickerState.Node(group, previous: self.currentState),
                                                                       completion: self.completion),
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
        }.navigationBarTitle(currentState.parentGroup.groupName ?? "")
        .sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }.modifier(ServicesViewModifier(environment: self.environment))
        }
    }
}

struct TypePickerGroups_Previews: PreviewProvider {
    static var previews: some View {
        let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
        let category = try! context.fetch(SDEDgmppItemCategory.category(categoryID: .hi)).first!

        let group = try? context.from(SDEDgmppItemGroup.self).filter(/\SDEDgmppItemGroup.category == category && /\SDEDgmppItemGroup.parentGroup == nil).first()
        let state = TypePickerState()
        return NavigationView {
            TypePickerGroups(category: category,
                             currentState: TypePickerState.Node(group!),
                             completion: {_ in },
                             selectedGroup: .constant(nil))
        }
            .environment(\.managedObjectContext, context)
        .environmentObject(state)
    }
}
