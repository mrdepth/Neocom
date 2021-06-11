//
//  LocationPickerSolarSystems.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/2/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import CoreData

struct LocationPickerSolarSystems: View {
    var region: SDEMapRegion
    var completion: (NSManagedObject) -> Void
    
    @FetchRequest(sortDescriptors: [])
    private var solarSystems: FetchedResults<SDEMapSolarSystem>
    
    
    init(region: SDEMapRegion, completion: @escaping (NSManagedObject) -> Void) {
        self.region = region
        self.completion = completion
        _solarSystems = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SDEMapSolarSystem.solarSystemName, ascending: true)], predicate: (/\SDEMapSolarSystem.constellation?.region == region).predicate(), animation: nil)
    }
    
    var body: some View {
        List(solarSystems, id: \.objectID) { solarSystem in
            Button(action: {self.completion(solarSystem)}) {
                SolarSystemCell(solarSystem: solarSystem)
            }.buttonStyle(PlainButtonStyle())
        }.listStyle(GroupedListStyle())
            .navigationBarTitle(region.regionName ?? "")
    }
}

struct SolarSystemCell: View {
    var solarSystem: SDEMapSolarSystem
    
    var body: some View {
        HStack {
            Text(String(format: "%.1f", solarSystem.security)).foregroundColor(Color.security(solarSystem.security))
            Text(solarSystem.solarSystemName ?? "")
            Spacer()
        }.frame(minHeight: 30).contentShape(Rectangle())
    }
}

#if DEBUG
struct LocationPickerSolarSystems_Previews: PreviewProvider {
    static var previews: some View {
        let region = try! Storage.testStorage.persistentContainer.viewContext.from(SDEMapRegion.self).first()!
        return NavigationView {
            LocationPickerSolarSystems(region: region) { _ in }
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
