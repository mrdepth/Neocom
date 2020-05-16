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
    
    private func getCategories() -> FetchedResultsController<SDEInvCategory> {
        let controller = managedObjectContext.from(SDEInvCategory.self)
            .filter((/\SDEInvCategory.categoryID).in([SDECategoryID.ship.rawValue, SDECategoryID.structure.rawValue]))
            .sort(by: \SDEInvCategory.categoryName, ascending: true)
            .fetchedResultsController(sectionName: /\SDEInvCategory.published)
        return FetchedResultsController(controller)
    }
    private let categories = Lazy<FetchedResultsController<SDEInvCategory>, Never>()
    @State private var searchString: String = ""
    @State private var searchResults: [FetchedResultsController<SDEInvType>.Section]? = nil

    
    var body: some View {
        let categories = self.categories.get(initial: getCategories())
        
        return TypesSearch(searchString: $searchString, searchResults: $searchResults) {
            if self.searchResults != nil {
                TypePickerTypesContent(types: self.searchResults!, selectedType: self.$selectedType, completion: self.completion)
            }
            else {
                ShipPickerCategoriesContent(categories: categories, completion: self.completion)
            }
        }
        .navigationBarTitle("Categories")
        .sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
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
        }.environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
