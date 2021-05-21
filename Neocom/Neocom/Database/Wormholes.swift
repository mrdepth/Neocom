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
        
        return List {
            WormholesContent(wormholes: wormholes)
        }
        .listStyle(GroupedListStyle())
        .search { publisher in
            WormholesSearchResults(publisher: publisher)
        }
        .navigationBarTitle(Text("Wormholes"))
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

struct WormholesSearchResults: View {
    var publisher: AnyPublisher<String?, Never>
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var results: FetchedResultsController<SDEWhType>?
    
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
        List {
            results.map {
                WormholesContent(wormholes: $0)
            }
        }
        .listStyle(GroupedListStyle())
        .onReceive(publisher.compactMap{$0}.debounce(for: .seconds(0.25), scheduler: DispatchQueue.main).flatMap{self.search($0)}) { results in
            self.results = results
        }
    }
}


struct Wormholes_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Wormholes()
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
