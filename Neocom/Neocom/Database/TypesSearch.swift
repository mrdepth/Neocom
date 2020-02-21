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
    var content: ([FetchedResultsController<SDEInvType>.Section]?) -> Content
    var onUpdated: ((String) -> Void)?
    var searchString: String
    
    init(searchString: String = "", predicate: PredicateProtocol? = nil, onUpdated: ((String) -> Void)? = nil, @ViewBuilder content: @escaping ([FetchedResultsController<SDEInvType>.Section]?) -> Content) {
        self.searchString = searchString
        self.predicate = predicate
        self.content = content
        self.onUpdated = onUpdated
    }
    
    func search(_ string: String) -> AnyPublisher<[FetchedResultsController<SDEInvType>.Section]?, Never> {
        return Future<FetchedResultsController<NSDictionary>?, Never> { promise in
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
        SearchView(initialValue: nil, predicate: searchString, search: search, onUpdated: onUpdated) { results in
            self.content(results)
        }
    }
}

struct TypesSearch_Previews: PreviewProvider {
    static var previews: some View {
        TypesSearch { results in
            EmptyView()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, (UIApplication.shared.delegate as! AppDelegate).persistentContainer.newBackgroundContext())
    }
}
