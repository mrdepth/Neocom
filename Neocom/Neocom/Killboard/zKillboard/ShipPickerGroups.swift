//
//  ShipPickerGroups.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/2/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible

struct ShipPickerGroups: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var selectedType: SDEInvType?
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    var category: SDEInvCategory
    var completion: (NSManagedObject) -> Void
    
    private func groups() -> FetchedResultsController<SDEInvGroup> {
        let controller = managedObjectContext.from(SDEInvGroup.self)
            .filter(/\SDEInvGroup.category == category && /\SDEInvGroup.published == true)
            .sort(by: \SDEInvGroup.groupName, ascending: true)
            .fetchedResultsController(sectionName: /\SDEInvGroup.published)
        return FetchedResultsController(controller)
    }
    
    var body: some View {
        ObservedObjectView(self.groups()) { groups in
            TypesSearch(predicate: /\SDEInvType.group?.category == self.category && /\SDEInvType.published == true) { searchResults in
                List {
                    if searchResults == nil {
                        ShipPickerGroupsContent(groups: groups, completion: self.completion)
                    }
                    else {
                        TypePickerTypesContent(types: searchResults!, selectedType: self.$selectedType, completion: self.completion)
                    }
                }.listStyle(GroupedListStyle())
                    .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }
        }.navigationBarTitle(category.categoryName ?? NSLocalizedString("Categories", comment: ""))
            .sheet(item: $selectedType) { type in
                NavigationView {
                    TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
                }.modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
        }
    }
    
}

struct ShipPickerGroupsContent: View {
    var groups: FetchedResultsController<SDEInvGroup>
    var completion: (NSManagedObject) -> Void
    
    var body: some View {
        ForEach(groups.sections, id: \.name) { section in
            Section(header: section.name == "0" ? Text("UNPUBLISHED") : Text("PUBLISHED")) {
                ForEach(section.objects, id: \.objectID) { group in
                    NavigationLink(destination: ShipPickerTypes(parentGroup: group, completion: self.completion)) {
                        HStack {
                            GroupCell(group: group)
                            Spacer()
                            Button("Select") {
                                self.completion(group)
                            }.foregroundColor(.blue)
                        }
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct ShipPickerTypes: View {
    var parentGroup: SDEInvGroup
    var completion: (SDEInvType) -> Void
    @State private var selectedType: SDEInvType?
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    
    var predicate: PredicateProtocol {
        /\SDEInvType.group == parentGroup && /\SDEInvType.published == true
    }
    
    private func types() -> FetchedResultsController<SDEInvType> {
        Types.fetchResults(with: predicate, managedObjectContext: managedObjectContext)
    }

    var body: some View {
        ObservedObjectView(self.types()) { types in
            TypesSearch(searchString: "", predicate: self.predicate) { searchResults in
                List {
                    TypePickerTypesContent(types: searchResults ?? types.sections, selectedType: self.$selectedType, completion: self.completion)
                }.listStyle(GroupedListStyle())
                    .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }
        }.navigationBarTitle(parentGroup.groupName ?? "")
        .sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }.modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
        }

    }
}

struct ShipPickerGroups_Previews: PreviewProvider {
    static var previews: some View {
        let category = try? AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEInvCategory.self).filter(/\SDEInvCategory.categoryID == SDECategoryID.ship.rawValue).first()
        return NavigationView {
            ShipPickerGroups(category: category!) { _ in}
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
