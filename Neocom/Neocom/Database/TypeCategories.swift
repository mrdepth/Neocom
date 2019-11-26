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
    @State private var categories: FetchedResultsController<SDEInvCategory>
    init() {
        let context = AppDelegate.sharedDelegate.storageContainer.viewContext
        let categories = context.from(SDEInvCategory.self)
            .sort(by: \SDEInvCategory.published, ascending: false)
            .sort(by: \SDEInvCategory.categoryName, ascending: true)
            .fetchedResultsController(sectionName: \SDEInvCategory.published)
        _categories = State(initialValue: FetchedResultsController(categories))
    }
    
    var body: some View {
        List {
            ForEach(categories.sections, id: \.name) { section in
                Section(header: section.name == "0" ? Text("UNPUBLISHED") : Text("PUBLISHED")) {
                    ForEach(section.objects, id: \.objectID) { category in
                        Text(category.categoryName ?? "")
                    }
                }
            }
        }.listStyle(GroupedListStyle()).navigationBarTitle("Categories")
    }
}

struct TypeCategories_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TypeCategories()
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.testingContainer.viewContext)
    }
}
