//
//  ExtractorSection.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible

struct ExtractorSection: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var extractor: DGMExtractorControlUnit
    
    private var states: [DGMProductionState]
    private var wasteStates: [DGMProductionState]
    private var points: [BarChart.Point]
    init(extractor: DGMExtractorControlUnit) {
        self.extractor = extractor
        states = extractor.states.filter{$0.cycle != nil}
        wasteStates = states.filter {$0.cycle!.waste.quantity > 0}
        
        points = states.map {
            BarChart.Point(timestamp: $0.timestamp,
                           duration: $0.cycle!.duration,
                           yield: Double($0.cycle!.yield.quantity),
                           waste: Double($0.cycle!.waste.quantity))
        }

    }
    
    var body: some View {
        
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(extractor.typeID)).first()
        let currentTime = Date()
        let wasteState = wasteStates.first {$0.timestamp > currentTime} ?? wasteStates.first
        
        let yield = states.map{$0.cycle!.yield.quantity}.reduce(0, +)
        let waste = wasteStates.map{$0.cycle!.waste.quantity}.reduce(0, +)
        
        
        let max = points.map{$0.yield + $0.waste}.max() ?? 1
        
        return Section(header: Text(extractor.name)) {
            if type != nil {
                NavigationLink(destination: TypeInfo(type: type!)) {
                    HStack {
                        Icon(type!.image).cornerRadius(4)
                        Text(type!.typeName ?? "")
                    }
                }
            }
            BarChart(startDate: extractor.installTime, endDate: extractor.expiryTime, points: points, capacity: max)
            extractor.output.map{FactoryOutputCell(commodity: $0)}
            if wasteState != nil {
                WasteCell(yield: yield, waste: waste, wasteState: wasteState!)
            }
            ExtractorStatisticCell(extractor: extractor, states: states, yield: yield, waste: waste)
        }
    }
}

struct WasteCell: View {
    var yield: Int
    var waste: Int
    var wasteState: DGMProductionState
    @State private var currentTime = Date()
    
    var body: some View {
        let t = wasteState.timestamp.timeIntervalSince(currentTime)
        let p = Int(Double(waste) / Double(waste + yield) * 100)

        return Group {
            if t > 0 {
                Text("Waste in \(TimeIntervalFormatter.localizedString(from: t, precision: .seconds)) (\(p)%)")
                    .onReceive(Timer.publish(every: 1, on: RunLoop.main, in: .default).autoconnect()) { _ in
                        self.currentTime = Date()
                }
            }
            else {
                Text("Waste \(p)%")
            }
        }
    }
}

struct ExtractorStatisticCell: View {
    var extractor: DGMExtractorControlUnit
    var states: [DGMProductionState]
    var yield: Int
    var waste: Int
    @State private var currentTime = Date()
    
    var body: some View {
        let duration = extractor.expiryTime.timeIntervalSince(extractor.installTime)
        let currentState = states.filter{$0.timestamp < currentTime}.last
        let sum = yield + waste
        let remains = extractor.expiryTime.timeIntervalSince(currentTime)
        return HStack {
            VStack(alignment: .trailing) {
                Text("Sum (units):")
                Text("Yield (units/h):")
                Text("Cycle Time:")
                Text("Current Cycle:")
                Text("Time to Depletion:")
            }.foregroundColor(.skyBlue)
            VStack(alignment: .leading) {
                Text(UnitFormatter.localizedString(from: sum, unit: .none, style: .long))
                Text(UnitFormatter.localizedString(from: Double(sum) * 3600 / Double(duration), unit: .none, style: .long))
                Text(TimeIntervalFormatter.localizedString(from: extractor.cycleTime, precision: .hours, format: .colonSeparated))
                if currentState != nil && remains > 0 {
                    Text(TimeIntervalFormatter.localizedString(from: currentTime.timeIntervalSince(currentState!.timestamp), precision: .hours, format: .colonSeparated))
                    Text(TimeIntervalFormatter.localizedString(from: remains, precision: .seconds))
                        .foregroundColor(remains > 3600 * 24 ? .primary : .yellow)
                        .onReceive(Timer.publish(every: 1, on: RunLoop.main, in: .default).autoconnect()) { _ in
                            self.currentTime = Date()
                    }
                }
                else {
                    Text(TimeIntervalFormatter.localizedString(from: 0, precision: .hours, format: .colonSeparated))
                    Text(TimeIntervalFormatter.localizedString(from: 0, precision: .seconds)).foregroundColor(.red)
                }
            }
        }
        .font(.footnote)
        .onReceive(Timer.publish(every: 1, on: RunLoop.main, in: .default).autoconnect()) { _ in
            self.currentTime = Date()
        }
    }
}

struct ExtractorSection_Previews: PreviewProvider {
    static var previews: some View {
        let planet = DGMPlanet.testPlanet()
        planet.run()
        let ecu = planet.facilities.first{$0 is DGMExtractorControlUnit} as? DGMExtractorControlUnit
        return NavigationView {
            List {
                ExtractorSection(extractor: ecu!)
            }.listStyle(GroupedListStyle())
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(planet)
    }
}
