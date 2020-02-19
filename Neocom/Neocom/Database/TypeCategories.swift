//
//  TypeCategories.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/26/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible
import Combine

struct TypeCategories: View {
    @Environment(\.managedObjectContext) var managedObjectContext
	
    private func categories() -> FetchedResultsController<SDEInvCategory> {
        let controller = managedObjectContext.from(SDEInvCategory.self)
            .sort(by: \SDEInvCategory.published, ascending: false)
            .sort(by: \SDEInvCategory.categoryName, ascending: true)
            .fetchedResultsController(sectionName: Expressions.keyPath(\SDEInvCategory.published))
        return FetchedResultsController(controller)
    }
    
    var body: some View {
        ObservedObjectView(self.categories()) { categories in
            TypesSearch { searchResults in
                List {
                    if searchResults == nil {
                        TypeCategoriesContent(categories: categories)
                    }
                    else {
                        TypesContent(types: searchResults!)
                    }
                }.listStyle(GroupedListStyle())
                    .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }.navigationBarTitle("Categories")
        }
    }
}

struct TypeCategoriesContent: View {
	var categories: FetchedResultsController<SDEInvCategory>
	
	var body: some View {
		ForEach(categories.sections, id: \.name) { section in
			Section(header: section.name == "0" ? Text("UNPUBLISHED") : Text("PUBLISHED")) {
				ForEach(section.objects, id: \.objectID) { category in
                    NavigationLink(destination: TypeGroups(category: category)) {
                        CategoryCell(category: category)
                    }
				}
			}
		}
	}
}

struct TypeCategories_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TypeCategories()
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext())
    }
}

