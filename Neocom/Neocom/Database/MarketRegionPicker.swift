//
//  MarketRegionPicker.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/13/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import Combine

struct MarketRegionPicker: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
    
    private func regions() -> FetchedResultsController<SDEMapRegion> {
        let controller = managedObjectContext.from(SDEMapRegion.self)
            .sort(by: \SDEMapRegion.securityClass, ascending: false)
            .sort(by: \SDEMapRegion.regionName, ascending: true)
            .fetchedResultsController(sectionName: \SDEMapRegion.securityClassDisplayName)
        return FetchedResultsController(controller)
    }

    func search(_ string: String) -> Just<[FetchedResultsController<SDEMapRegion>.Section]?> {
        let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !string.isEmpty else { return Just(nil) }
        
        
        let controller = managedObjectContext.from(SDEMapRegion.self)
            .filter((\SDEMapRegion.regionName).caseInsensitive.contains(string))
            .sort(by: \SDEMapRegion.securityClass, ascending: false)
            .sort(by: \SDEMapRegion.regionName, ascending: true)
            .fetchedResultsController(sectionName: \SDEMapRegion.securityClassDisplayName)
        return Just(FetchedResultsController(controller).sections)
        
//        return Future { promise in
//            self.backgroundManagedObjectContext.perform {
//
//            }
//        }.eraseToAnyPublisher()
    }
    
    var body: some View {
        ObservedObjectView(self.regions()) { regions in
            SearchView(initialValue: nil, search: self.search) { searchResults in
                List {
                    ForEach(searchResults ?? regions.sections, id: \.name) { section in
                        Section(header: Text(section.name.uppercased())) {
                            ForEach(section.objects, id: \.objectID) { region in
                                Button(region.regionName ?? "") {
                                }.accentColor(.primary)
                            }
                        }
                    }
                    
                }.listStyle(GroupedListStyle())
            }
        }
    }
}

struct MarketRegionPicker_Previews: PreviewProvider {
    static var previews: some View {
        MarketRegionPicker()
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext.newBackgroundContext())
    }
}
