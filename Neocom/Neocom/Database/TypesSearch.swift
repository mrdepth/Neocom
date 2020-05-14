//
//  TypesSearch.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/28/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine
import Expressible
import CoreData

struct TypesSearch<Content: View>: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
    var predicate: PredicateProtocol? = nil
    @Binding var searchString: String
    @Binding var searchResults: [FetchedResultsController<SDEInvType>.Section]?
    var content: () -> Content
    
    @State private var isEditing = false

    init(predicate: PredicateProtocol? = nil, searchString: Binding<String>, searchResults: Binding<[FetchedResultsController<SDEInvType>.Section]?>, @ViewBuilder content: @escaping () -> Content) {
        self.predicate = predicate
        _searchString = searchString
        _searchResults = searchResults
        self.content = content
    }

    func search(_ string: String) -> AnyPublisher<[FetchedResultsController<SDEInvType>.Section]?, Never> {
        Future<FetchedResultsController<NSDictionary>?, Never> { promise in
            self.backgroundManagedObjectContext.perform {
                let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if string.isEmpty {
                    promise(.success(nil))
                }
                else {
                    var request = self.backgroundManagedObjectContext.from(SDEInvType.self)
                    if let predicate = self.predicate {
                        request = request.filter(predicate)
                    }
                    request = request.filter((/\SDEInvType.typeName).caseInsensitive.contains(string))
                    let controller = request.sort(by: \SDEInvType.metaGroup?.metaGroupID, ascending: true)
                        .sort(by: \SDEInvType.metaLevel, ascending: true)
                        .sort(by: \SDEInvType.typeName, ascending: true)
                        .select([(/\SDEInvType.self).as(NSManagedObjectID.self, name: "objectID"), (/\SDEInvType.metaGroup?.metaGroupID).as(Int.self, name: "metaGroupID")])
                        .limit(100)
                        .fetchedResultsController(sectionName: (/\SDEInvType.metaGroup?.metaGroupName).as(Int.self, name: "metaGroupID"))
                    
                    try? controller.performFetch()
                    promise(.success(FetchedResultsController(controller)))
                }
                
            }
        }.receive(on: RunLoop.main).map { controller in
            controller?.sections.map{ section in
                FetchedResultsController<SDEInvType>.Section(name: section.name,
                                                             objects: section.objects
                                                                .compactMap{$0["objectID"] as? NSManagedObjectID}
                                                                .compactMap {self.managedObjectContext.object(with: $0) as? SDEInvType})
            }
        }.eraseToAnyPublisher()
    }
    
    var body: some View {
        SearchList(text: $searchString, results: $searchResults, isEditing: $isEditing, search: search, content: content)
        .listStyle(GroupedListStyle())
        .overlay(searchResults?.isEmpty == true ? Text(RuntimeError.noResult) : nil)
    }
}

#if DEBUG
struct TypesSearch_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TypeCategories()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())
    }
}
#endif
