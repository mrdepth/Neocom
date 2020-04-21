//
//  ShipPicker.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/2/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import CoreData

struct ShipPicker: View {
    var completion: (NSManagedObject) -> Void
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @State private var selectedType: SDEInvType?
    @EnvironmentObject private var sharedState: SharedState
    
    private func categories() -> FetchedResultsController<SDEInvCategory> {
        let controller = managedObjectContext.from(SDEInvCategory.self)
            .filter((/\SDEInvCategory.categoryID).in([SDECategoryID.ship.rawValue, SDECategoryID.structure.rawValue]))
            .sort(by: \SDEInvCategory.categoryName, ascending: true)
            .fetchedResultsController(sectionName: /\SDEInvCategory.published)
        return FetchedResultsController(controller)
    }
    
    var body: some View {
        ObservedObjectView(self.categories()) { categories in
            TypesSearch { searchResults in
                List {
                    if searchResults == nil {
                        ShipPickerCategoriesContent(categories: categories, completion: self.completion)
                    }
                    else {
                        TypePickerTypesContent(types: searchResults!, selectedType: self.$selectedType, completion: self.completion)
                        TypesContent(types: searchResults!) { type in
                            NavigationLink(destination: TypeInfo(type: type)) {
                                TypeCell(type: type)
                            }
                        }
                    }
                }.listStyle(GroupedListStyle())
                    .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }.navigationBarTitle("Categories")
        }.sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }.modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
        }

    }
}

struct ShipPickerCategoriesContent: View {
    var categories: FetchedResultsController<SDEInvCategory>
    var completion: (NSManagedObject) -> Void
    
    var body: some View {
        ForEach(categories.sections, id: \.name) { section in
            Section(header: section.name == "0" ? Text("UNPUBLISHED") : Text("PUBLISHED")) {
                ForEach(section.objects, id: \.objectID) { category in
                    NavigationLink(destination: ShipPickerGroups(category: category, completion: self.completion)) {
                        CategoryCell(category: category)
                    }
                }
            }
        }
    }
}


struct ShipPicker_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ShipPicker { _ in
                
            }
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
