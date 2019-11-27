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
            .fetchedResultsController(sectionName: \SDEInvCategory.published)
        return FetchedResultsController(controller)
    }
    
    var body: some View {
        TypesSearchResults(backgroundContext: managedObjectContext, viewContext: managedObjectContext, predicate: nil) { searchResults in
            FetchedResultsView(self.categories()) { categories in
                List {
                    TypeCategoriesContent(categories: categories)
                }.listStyle(GroupedListStyle()).navigationBarTitle("Categories")
            }
        }
    }
}

struct TypesSearchResults<Content: View>: View {
    @ObservedObject var searchResults: SearchResults<[FetchedResultsController<SDEInvType>.Section]>
    var content: ([FetchedResultsController<SDEInvType>.Section]) -> Content
    
    init(backgroundContext: NSManagedObjectContext, viewContext: NSManagedObjectContext, predicate: Predictable?, content: @escaping ([FetchedResultsController<SDEInvType>.Section]) -> Content) {
        self.content = content
        
        searchResults = SearchResults(initialValue: []) { string in
            Future<FetchedResultsController<NSDictionary>, Never> { promise in
                backgroundContext.perform {
                    var request = backgroundContext.from(SDEInvType.self)
                    if string.count < 3 {
                        request = request.filter(false)
                    }
                    else {
                        if let predicate = predicate {
                            request = request.filter(predicate)
                        }
                        request = request.filter((\SDEInvType.typeName).caseInsensitive.contains(string))
                    }

                    let controller = request.sort(by: \SDEInvType.metaGroup?.metaGroupID, ascending: true)
                        .sort(by: \SDEInvType.metaLevel, ascending: true)
                        .sort(by: \SDEInvType.typeName, ascending: true)
                        .select([(\SDEInvType.objectID).as(String.self, name: "objectID"), (\SDEInvType.metaGroup?.metaGroupName).as(String.self, name: "metaGroupName")])
                        .fetchedResultsController(sectionName: (\SDEInvType.metaGroup?.metaGroupName).as(String.self, name: "metaGroupName"))

                    try? controller.performFetch()
                    promise(.success(FetchedResultsController(controller)))
                }
            }
            .receive(on: DispatchQueue.main)
            .map{
                $0.sections.map{
                    FetchedResultsController<SDEInvType>.Section(name: $0.name,
                                                                 objects: $0.objects.map{
                                                                    viewContext.object(with: $0["objectID"] as! NSManagedObjectID) as! SDEInvType
                        }
                    )
                }
            }
        }
    }
    
    var body: some View {
        content(searchResults.results)
    }
}

struct TypeCategoriesContent: View {
	var categories: FetchedResultsController<SDEInvCategory>
	
	var body: some View {
		ForEach(categories.sections, id: \.name) { section in
			Section(header: section.name == "0" ? Text("UNPUBLISHED") : Text("PUBLISHED")) {
				ForEach(section.objects, id: \.objectID) { category in
                    NavigationLink(destination: TypeGroups(category: category)) {
                        HStack {
                            Icon(category.image)
                            Text(category.categoryName ?? "")
                        }
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
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.storageContainer.viewContext)
    }
}
