//
//  StorageSection.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/31/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible

struct StorageSection: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var storage: DGMStorage
    
    private var states: [DGMState]
    private var points: [BarChart.Point]
    
    init(storage: DGMStorage) {
        self.storage = storage
        let states = storage.states
        self.states = states
        
        points = states.indices.dropLast().map { i in
            BarChart.Point(timestamp: states[i].timestamp,
                           duration: states[i + 1].timestamp.timeIntervalSince(states[i].timestamp),
                           yield: states[i].volume,
                           waste: 0)
        }
        
        if let state = states.last {
            points.append(BarChart.Point(timestamp: state.timestamp,
                                         duration: 2 * 3600,
                                         yield: state.volume,
                                         waste: 0))
        }
    }

    
    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(storage.typeID)).first()
        let currentTime = Date()
        let currentState = states.filter{$0.timestamp < currentTime}.last
        let capacity = storage.capacity
        let used = currentState?.volume ?? 0
        
        let startDate = points.first?.timestamp ?? Date.distantPast
        let endDate = points.last.map{$0.timestamp.addingTimeInterval($0.duration)} ?? Date.distantPast

        return Section(header: Text(storage.name)) {
            if type != nil {
                NavigationLink(destination: TypeInfo(type: type!)) {
                    HStack {
                        Icon(type!.image).cornerRadius(4)
                        VStack(alignment: .leading) {
                            Text(type!.typeName ?? "")
                            if capacity > 0 {
                                Text("\(UnitFormatter.localizedString(from: used, unit: .none, style: .long)) / \(UnitFormatter.localizedString(from: capacity, unit: .cubicMeter, style: .long)) (\(Int(used / capacity * 100))%)").modifier(SecondaryLabelModifier())
                            }
                            
                        }
                    }
                }
            }
            if points.count > 1 {
                BarChart(startDate: startDate, endDate: endDate, points: points, capacity: capacity)
            }
            if currentState != nil {
                ForEach(currentState!.commodities, id: \.typeID) {
                    CommodityCell(commodity: $0)
                }
            }
        }
    }
}

struct CommodityCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var commodity: DGMCommodity
    
    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(commodity.typeID)).first()
        let content = HStack {
            type.map{Icon($0.image)}.cornerRadius(4)
            VStack(alignment: .leading) {
                Text(type?.typeName ?? "")
                Text("\(UnitFormatter.localizedString(from: commodity.quantity, unit: .none, style: .long)) (\(UnitFormatter.localizedString(from: commodity.volume * Double(commodity.quantity), unit: .cubicMeter, style: .long)))").modifier(SecondaryLabelModifier())
            }
        }

        return Group {
            if type != nil {
                NavigationLink(destination: TypeInfo(type: type!)) {
                    content
                }
            }
            else {
                content
            }
        }

    }
}

struct StorageSection_Previews: PreviewProvider {
    static var previews: some View {
        let planet = DGMPlanet.testPlanet()
        planet.run()
        let storage = planet.facilities.first{$0 is DGMStorage} as? DGMStorage
        return NavigationView {
            List {
                StorageSection(storage: storage!)
            }.listStyle(GroupedListStyle())
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(planet)
    }
}
