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
    
    private func getGroups() -> FetchedResultsController<SDEInvGroup> {
        let controller = managedObjectContext.from(SDEInvGroup.self)
            .filter(/\SDEInvGroup.category == category && /\SDEInvGroup.published == true)
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
                TypePickerTypesContent(types: self.searchResults!, selectedType: self.$selectedType, completion: self.completion)
            }
            else {
                ShipPickerGroupsContent(groups: groups, completion: self.completion)
            }
        }
        .navigationBarTitle(category.categoryName ?? NSLocalizedString("Categories", comment: ""))
            .sheet(item: $selectedType) { type in
                NavigationView {
                    TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
                }
                .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
                .navigationViewStyle(StackNavigationViewStyle())
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
    
    private func getTypes() -> FetchedResultsController<SDEInvType> {
        Types.fetchResults(with: predicate, managedObjectContext: managedObjectContext)
    }
    private let types = Lazy<FetchedResultsController<SDEInvType>, Never>()
    @State private var searchString: String = ""
    @State private var searchResults: [FetchedResultsController<SDEInvType>.Section]? = nil

    var body: some View {
        let types = self.types.get(initial: getTypes())
        
        return TypesSearch(predicate: self.predicate, searchString: $searchString, searchResults: $searchResults) {
            TypePickerTypesContent(types: self.searchResults ?? types.sections, selectedType: self.$selectedType, completion: self.completion)
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

struct ShipPickerGroups_Previews: PreviewProvider {
    static var previews: some View {
        let category = try? Storage.sharedStorage.persistentContainer.viewContext.from(SDEInvCategory.self).filter(/\SDEInvCategory.categoryID == SDECategoryID.ship.rawValue).first()
        return NavigationView {
            ShipPickerGroups(category: category!) { _ in}
        }.environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
