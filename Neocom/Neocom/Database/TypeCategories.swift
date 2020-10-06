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
    @Environment(\.managedObjectContext) private var managedObjectContext
	
    private func getCategories() -> FetchedResultsController<SDEInvCategory> {
        let controller = managedObjectContext.from(SDEInvCategory.self)
            .sort(by: \SDEInvCategory.published, ascending: false)
            .sort(by: \SDEInvCategory.categoryName, ascending: true)
            .fetchedResultsController(sectionName: /\SDEInvCategory.published)
        return FetchedResultsController(controller)
    }
    
    private let categories = Lazy<FetchedResultsController<SDEInvCategory>, Never>()
    
    @State private var searchString: String = ""
    @State private var searchResults: [FetchedResultsController<SDEInvType>.Section]? = nil
    
    var body: some View {
        let categories = self.categories.get(initial: getCategories())
        
        return List {
            TypeCategoriesContent(categories: categories)
        }
        .listStyle(GroupedListStyle())
        .search { publisher in
            TypesSearchResults(publisher: publisher) { type in
                NavigationLink(destination: TypeInfo(type: type)) {
                    TypeCell(type: type)
                }
            }
        }
        .navigationBarTitle(Text("Categories"))
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

#if DEBUG
struct TypeCategories_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TypeCategories()
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
