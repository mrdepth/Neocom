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
import CoreData

struct MarketRegionPicker: View {
	var action: (SDEMapRegion) -> Void
	
	init(_ action: @escaping (SDEMapRegion) -> Void) {
		self.action = action
	}
	
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
	
	private struct Row: Identifiable {
		var id: NSManagedObjectID
		var regionID: NSManagedObjectID
		var title: String
		var subtitle: String?
	}
    
    private func regions() -> FetchedResultsController<SDEMapRegion> {
        let controller = managedObjectContext.from(SDEMapRegion.self)
            .sort(by: \SDEMapRegion.securityClass, ascending: false)
            .sort(by: \SDEMapRegion.regionName, ascending: true)
            .fetchedResultsController(sectionName: Expressions.keyPath(\SDEMapRegion.securityClassDisplayName))
        return FetchedResultsController(controller)
    }

    private func search(_ string: String) -> AnyPublisher<(regions: [Row], solarSystems: [Row])?, Never> {
        let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !string.isEmpty else { return Just(nil).eraseToAnyPublisher() }
        
		return Future { promise in
            self.backgroundManagedObjectContext.perform {
				let regions = try? self.managedObjectContext.from(SDEMapRegion.self)
					.filter(Expressions.keyPath(\SDEMapRegion.regionName).caseInsensitive.contains(string))
					.sort(by: \SDEMapRegion.regionName, ascending: true)
					.fetch()
					.map{Row(id: $0.objectID, regionID: $0.objectID, title: $0.regionName ?? "", subtitle: nil)}

				let solarSystems = try? self.managedObjectContext
					.from(SDEMapSolarSystem.self)
					.filter(Expressions.keyPath(\SDEMapSolarSystem.constellation?.region?.regionID) < SDERegionID.whSpace.rawValue)
					.filter(Expressions.keyPath(\SDEMapSolarSystem.solarSystemName).caseInsensitive.contains(string))
					.sort(by: \SDEMapSolarSystem.solarSystemName, ascending: true)
					.subrange(0..<50)
					.fetch()
					.map{Row(id: $0.objectID, regionID: $0.constellation!.region!.objectID, title: $0.constellation?.region?.regionName ?? "", subtitle: $0.solarSystemName)}
				
				promise(.success((regions: regions ?? [], solarSystems: solarSystems ?? [])))
            }
		}.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
	
	private func regionCell(_ region: SDEMapRegion) -> some View {
		Button(region.regionName ?? "") {
			self.action(region)
		}.accentColor(.primary)
	}

	private func cell(for row: Row) -> some View {
		Button(action: {
			let region = self.managedObjectContext.object(with: row.regionID) as! SDEMapRegion
			self.action(region)
		}) {
			VStack(alignment: .leading) {
				Text(row.title)
				row.subtitle.map{Text($0).foregroundColor(.secondary)}
			}
		}.accentColor(.primary)
	}
	
	private func sections(from regions: FetchedResultsController<SDEMapRegion>) -> some View {
		ForEach(regions.sections, id: \.name) { section in
			Section(header: Text(section.name.uppercased())) {
				ForEach(section.objects, id: \.objectID) { region in
					self.regionCell(region)
				}
			}
		}
	}

	private func sections(from searchResults: (regions: [Row], solarSystems: [Row])) -> some View {
		Group {
			if !searchResults.regions.isEmpty {
				Section(header: Text("REGIONS")) {
					ForEach(searchResults.regions) { region in
						self.cell(for: region)
					}
				}
			}
			if !searchResults.solarSystems.isEmpty {
				Section(header: Text("SOLAR SYSTEMS")) {
					ForEach(searchResults.solarSystems) { solarSystem in
						self.cell(for: solarSystem)
					}
				}
			}
		}
	}

    var body: some View {
        ObservedObjectView(self.regions()) { regions in
            SearchView(initialValue: nil, search: self.search) { searchResults in
                List {
					if searchResults == nil {
						self.sections(from: regions)
					}
					else {
						self.sections(from: searchResults!)
					}
                }.listStyle(GroupedListStyle())
            }
		}.navigationBarTitle("Regions")
    }
}

struct MarketRegionPicker_Previews: PreviewProvider {
    static var previews: some View {
		MarketRegionPicker { _ in}
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext.newBackgroundContext())
    }
}
