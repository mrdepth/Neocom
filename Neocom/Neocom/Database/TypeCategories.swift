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
	var managedObjectContext: NSManagedObjectContext
    @State private var categories: FetchedResultsController<SDEInvCategory>
	
    init(managedObjectContext: NSManagedObjectContext) {
		self.managedObjectContext = managedObjectContext
        let categories = managedObjectContext.from(SDEInvCategory.self)
            .sort(by: \SDEInvCategory.published, ascending: false)
            .sort(by: \SDEInvCategory.categoryName, ascending: true)
            .fetchedResultsController(sectionName: \SDEInvCategory.published)
        _categories = State(initialValue: FetchedResultsController(categories))
    }
    
    var body: some View {
        List {
			TypeCategoriesContent(categories: categories)
        }.listStyle(GroupedListStyle()).navigationBarTitle("Categories")
    }
}

struct TypeCategoriesContent: View {
	var categories: FetchedResultsController<SDEInvCategory>
	
	var body: some View {
		ForEach(categories.sections, id: \.name) { section in
			Section(header: section.name == "0" ? Text("UNPUBLISHED") : Text("PUBLISHED")) {
				ForEach(section.objects, id: \.objectID) { category in
					HStack {
						Icon(category.image)
						Text(category.categoryName ?? "")
					}
				}
			}
		}
	}
}

struct TypeCategories_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TypeCategories(managedObjectContext: AppDelegate.sharedDelegate.storageContainer.viewContext)
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.testingContainer.viewContext)
    }
}
