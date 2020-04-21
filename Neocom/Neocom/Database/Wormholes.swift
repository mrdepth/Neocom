//
//  Wormholes.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible
import Combine

struct Wormholes: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    private let wormholes = Lazy<FetchedResultsController<SDEWhType>, Never>()
    
    private func getWormholes() -> FetchedResultsController<SDEWhType> {
        let controller = managedObjectContext.from(SDEWhType.self)
            .filter(/\SDEWhType.type != nil)
            .sort(by: \SDEWhType.targetSystemClass, ascending: true)
            .sort(by: \SDEWhType.type?.typeName, ascending: true)
            .fetchedResultsController(sectionName: /\SDEWhType.targetSystemClassDisplayName)
        return FetchedResultsController(controller)
    }
    
    
    var body: some View {
        let wormholes = self.wormholes.get(initial: getWormholes())
        return WormholesSearch { searchResults in
            List {
                WormholesContent(wormholes: searchResults ?? wormholes)
            }
        }.listStyle(GroupedListStyle())
            .navigationBarTitle("Wormholes")
    }
}

struct WormholesContent: View {
    var wormholes: FetchedResultsController<SDEWhType>
    
    var body: some View {
        ForEach(wormholes.sections, id: \.name) { section in
            Section(header: Text(section.name.uppercased())) {
                ForEach(section.objects, id: \.objectID) { wh in
                    NavigationLink(destination: TypeInfo(type: wh.type!)) {
                        WormholeCell(wormhole: wh)
                    }
                }
            }
        }
    }
}

struct WormholesSearch<Content: View>: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var content: (FetchedResultsController<SDEWhType>?) -> Content
    
    init(@ViewBuilder content: @escaping (FetchedResultsController<SDEWhType>?) -> Content) {
        self.content = content
    }
    
    func search(_ string: String) -> AnyPublisher<FetchedResultsController<SDEWhType>?, Never> {
        Future<FetchedResultsController<SDEWhType>?, Never> { promise in
            self.managedObjectContext.perform {
                let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
                if string.isEmpty {
                    promise(.success(nil))
                }
                else {
                    let controller = self.managedObjectContext.from(SDEWhType.self)
                        .filter(/\SDEWhType.type != nil)
                        .filter((/\SDEWhType.type?.typeName).caseInsensitive.contains(string))
                        .sort(by: \SDEWhType.targetSystemClass, ascending: true)
                        .sort(by: \SDEWhType.type?.typeName, ascending: true)
                        .fetchedResultsController(sectionName: /\SDEWhType.targetSystemClassDisplayName)
                    promise(.success(FetchedResultsController(controller)))
                }
            }
        }.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
        
    var body: some View {
        SearchView(initialValue: nil, predicate: "", search: search, onUpdated: nil) { results in
            self.content(results)
        }
    }
}


struct Wormholes_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Wormholes()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
    }
}
