//
//  TypesSearchResults.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Combine
import CoreData
import Expressible

struct TypesSearchResults<Cell: View>: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    var publisher: AnyPublisher<String?, Never>
    var predicate: PredicateProtocol? = nil
    var cell: (SDEInvType) -> Cell

    private func search(_ string: String) -> AnyPublisher<[FetchedResultsController<SDEInvType>.Section]?, Never> {
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
    
    @State private var results: [FetchedResultsController<SDEInvType>.Section]?
    
    var body: some View {
        List {
            results.map { results in
                TypesContent(types: results, cell: cell)
            }
        }
        .listStyle(GroupedListStyle())
            .onReceive(publisher.compactMap{$0}.debounce(for: .seconds(0.25), scheduler: DispatchQueue.main).flatMap{self.search($0)}) { results in
                self.results = results
            }
    }
}

struct TypesSearchResults_Previews: PreviewProvider {
    static var previews: some View {
        TypesSearchResults(publisher: Empty().eraseToAnyPublisher()) { type in
            TypeCell(type: type)
        }
    }
}
