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
    var predicate: Predictable? = nil
    var content: ([FetchedResultsController<SDEInvType>.Section]?) -> Content
    
    func search(_ string: String) -> AnyPublisher<[FetchedResultsController<SDEInvType>.Section]?, Never> {
        return Future<FetchedResultsController<NSDictionary>?, Never> { promise in
            self.backgroundManagedObjectContext.perform {
                if string.count < 3 {
                    promise(.success(nil))
                }
                else {
                    var request = self.backgroundManagedObjectContext.from(SDEInvType.self)
                    if let predicate = self.predicate {
                        request = request.filter(predicate)
                    }
                    request = request.filter((\SDEInvType.typeName).caseInsensitive.contains(string))
                    let controller = request.sort(by: \SDEInvType.metaGroup?.metaGroupID, ascending: true)
                        .sort(by: \SDEInvType.metaLevel, ascending: true)
                        .sort(by: \SDEInvType.typeName, ascending: true)
                        .select([_self.as(NSManagedObjectID.self, name: "objectID"), (\SDEInvType.metaGroup?.metaGroupName).as(String.self, name: "metaGroupName")])
                        .fetchedResultsController(sectionName: (\SDEInvType.metaGroup?.metaGroupName).as(String.self, name: "metaGroupName"))
                    
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
        SearchView(initialValue: nil, search: search) { results in
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
