//
//  LocationPicker.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/2/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import Combine
import CoreData

struct LocationPicker: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
    
    let regions = Lazy<FetchedResultsController<SDEMapRegion>, Never>()
    
    var completion: (NSManagedObject) -> Void
    
    private func getRegions() -> FetchedResultsController<SDEMapRegion> {
        let controller = managedObjectContext.from(SDEMapRegion.self)
            .sort(by: \SDEMapRegion.securityClass, ascending: false)
            .sort(by: \SDEMapRegion.regionName, ascending: true)
            .fetchedResultsController(sectionName: /\SDEMapRegion.securityClassDisplayName)
        return FetchedResultsController(controller)
    }

    private func regionCell(_ region: SDEMapRegion) -> some View {
        NavigationLink(destination: LocationPickerSolarSystems(region: region, completion: self.completion)) {
            HStack {
                Text(region.regionName ?? "")
                Spacer()
                Button(NSLocalizedString("Select", comment: "")) {
                    self.completion(region)
                }.foregroundColor(.blue)
            }
            .frame(height: 30)
            .contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
    }
    
    private func regionSearchCell(_ region: SDEMapRegion) -> some View {
        Button(action: {self.completion(region)}) {
            Text(region.regionName ?? "")
                .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                .contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
    }

    private func solarSystemCell(_ solarSystem: SDEMapSolarSystem) -> some View {
        Button(action: {self.completion(solarSystem)}) {
            SolarSystemCell(solarSystem: solarSystem)
        }.buttonStyle(PlainButtonStyle())
    }

    private func search(_ string: String) -> AnyPublisher<(regions: [NSManagedObjectID], solarSystems: [NSManagedObjectID])?, Never> {
        let string = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !string.isEmpty else { return Just(nil).eraseToAnyPublisher() }

        return Future { promise in
            self.backgroundManagedObjectContext.perform {
                let regions = try? self.managedObjectContext.from(SDEMapRegion.self)
                    .filter((/\SDEMapRegion.regionName).caseInsensitive.contains(string))
                    .sort(by: \SDEMapRegion.regionName, ascending: true)
                    .objectIDs
                    .fetch()

                let solarSystems = try? self.managedObjectContext
                    .from(SDEMapSolarSystem.self)
                    .filter(/\SDEMapSolarSystem.constellation?.region?.regionID < SDERegionID.whSpace.rawValue)
                    .filter((/\SDEMapSolarSystem.solarSystemName).caseInsensitive.contains(string))
                    .sort(by: \SDEMapSolarSystem.solarSystemName, ascending: true)
                    .subrange(0..<50)
                    .objectIDs
                    .fetch()
                
                promise(.success((regions: regions ?? [], solarSystems: solarSystems ?? [])))
            }
        }.receive(on: RunLoop.main).eraseToAnyPublisher()
    }
    
    var body: some View {
        let regions = self.regions.get(initial: getRegions())
        return
            SearchView(initialValue: nil, search: self.search) { searchResults in
                List {
                    if searchResults != nil {
                        if !searchResults!.regions.isEmpty {
                            Section(header: Text("REGIONS")) {
                                ForEach(searchResults!.regions, id: \.self) { objectID in
                                    self.regionSearchCell(self.managedObjectContext.object(with: objectID) as! SDEMapRegion)
                                }
                            }
                        }
                        if !searchResults!.solarSystems.isEmpty {
                            Section(header: Text("SOLAR SYSTEMS")) {
                                ForEach(searchResults!.solarSystems, id: \.self) { objectID in
                                    self.solarSystemCell(self.managedObjectContext.object(with: objectID) as! SDEMapSolarSystem)
                                }
                            }
                        }
                    }
                    else {
                        ForEach(regions.sections, id: \.name) { section in
                            Section(header: Text(section.name.uppercased())) {
                                ForEach(section.objects, id: \.objectID) { region in
                                    self.regionCell(region)
                                }
                            }
                        }
                    }
                }.listStyle(GroupedListStyle())
        }.navigationBarTitle(Text("Regions"))
    }
}

#if DEBUG
struct LocationPicker_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LocationPicker() { _ in
                
            }
        }
        .modifier(ServicesViewModifier.testModifier())

    }
}
#endif
