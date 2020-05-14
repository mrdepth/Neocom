//
//  FactorySection.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/31/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible

struct FactorySection: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var factory: DGMFactory
    
    private var states: [DGMProductionState]
    private var inputRatio: [Double]
    private var points: [BarChart.Point]

    init(factory: DGMFactory) {
        self.factory = factory
        let states = factory.states
        self.states = states

        var ratio: [Int: Double] = [:]

        for input in factory.inputs {
            let commodity = input.commodity
            guard let income = input.from?.income(typeID: commodity.typeID), income.quantity > 0 else {continue}
            ratio[income.typeID, default: 0] += Double(income.quantity)
        }

        let p = ratio.filter{$0.value > 0}.map{1.0 / $0.value}.max() ?? 1
        ratio = ratio.mapValues{value in ((value * p) * 10).rounded() / 10}
        inputRatio = ratio.sorted(by: {$0.key < $1.key}).map{$0.value}
        
        points = states.filter{$0.cycle != nil}.map {
            BarChart.Point(timestamp: $0.timestamp,
                           duration: $0.cycle!.duration,
                           yield: Double($0.cycle!.yield.quantity),
                           waste: Double($0.cycle!.waste.quantity))
        }
    }

    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(factory.typeID)).first()
        
        let lastState = states.reversed().first{$0.cycle == nil}
        let expiryTime = lastState?.timestamp ?? Date.distantPast
        
        let inputs = factory.inputs
        let output = factory.output

        let max = points.map{$0.yield + $0.waste}.max() ?? 1
        let start = states.first?.timestamp ?? .distantPast
        let end = states.last?.timestamp ?? .distantPast
        return Section(header: Text(factory.name)) {
            if type != nil {
                NavigationLink(destination: TypeInfo(type: type!)) {
                    HStack {
                        Icon(type!.image).cornerRadius(4)
                        Text(type!.typeName ?? "")
                    }
                }
            }
            ForEach(0..<inputs.count) { i in
                FactoryInputCell(input: inputs[i], expiryTime: expiryTime)
            }
            if output != nil {
                BarChart(startDate: start, endDate: end, points: points, capacity: max)
                FactoryOutputCell(commodity: output!)
            }
            FactorySatisticCell(factory: factory, states: states, inputRatio: inputRatio)
        }
    }
}


struct FactoryInputCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var input: DGMRoute
    var expiryTime: Date

    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(input.commodity.typeID)).first()
        
        return Group {
            if type != nil {
                NavigationLink(destination: TypeInfo(type: type!)) {
                    FactoryInputCellContent(type: type, input: input, expiryTime: expiryTime)
                }
            }
            else {
                FactoryInputCellContent(type: type, input: input, expiryTime: expiryTime)
            }
        }
    }
}

struct FactoryInputCellContent: View {
    var type: SDEInvType?
    var input: DGMRoute
    var expiryTime: Date
    @State private var currentTime = Date()

    var body: some View {
        let shortage = expiryTime.timeIntervalSince(currentTime)

        return HStack {
            type.map{Icon($0.image)}.cornerRadius(4)
            VStack(alignment: .leading) {
                Text("Input: \(type?.typeName ?? "")")//.modifier(SecondaryLabelModifier())
                if shortage <= 0  {
                    Text("Depleted").foregroundColor(.red).modifier(SecondaryLabelModifier())
                }
                else {
                    Text("Shortage in \(TimeIntervalFormatter.localizedString(from: shortage, precision: .seconds))").modifier(SecondaryLabelModifier())
                }
            }
        }.onReceive(Timer.publish(every: 1, on: RunLoop.main, in: .default).autoconnect()) { _ in
                self.currentTime = Date()
        }
    }
}

struct FactoryOutputCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var commodity: DGMCommodity
    
    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(commodity.typeID)).first()
        
        let content = HStack {
            type.map{Icon($0.image)}.cornerRadius(4)
            VStack(alignment: .leading) {
                Text("Output: \(type?.typeName ?? "")")//.modifier(SecondaryLabelModifier())
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

struct FactorySatisticCell: View {
    var factory: DGMFactory
    var states: [DGMProductionState]
    var inputRatio: [Double]
    @State private var currentTime = Date()
    
    var body: some View {
        let lastState = states.reversed().first{$0.cycle != nil}
        let currentState = states.filter{$0.timestamp < currentTime}.last
        let efficiency = currentState?.efficiency ?? 0
        let extrapolatedEfficiency = lastState?.efficiency ?? 0

        let ratio = inputRatio.map{UnitFormatter.localizedString(from: $0, unit: .none, style: .long)}.joined(separator: ":")
        
        return VStack(alignment: .leading) {
//            Text("Averaged Facility Performance:").foregroundColor(.skyBlue)
            HStack {
                VStack(alignment: .trailing) {
                    Text("Efficiency:")
                    Text("Extrapolated Efficiency:")
                    if inputRatio.count > 1 {
                        Text("Input Ratio:")
                    }
                }.foregroundColor(.skyBlue)
                VStack(alignment: .leading) {
                    Text("\(Int((efficiency * 100).rounded()))%")
                    Text("\(Int((extrapolatedEfficiency * 100).rounded()))%")
                    if inputRatio.count > 1 {
                        Text(ratio)
                    }
                }
            }.font(.footnote)
        }.onReceive(Timer.publish(every: 1, on: RunLoop.main, in: .default).autoconnect()) { _ in
            self.currentTime = Date()
        }
    }
}

struct FactorySection_Previews: PreviewProvider {
    static var previews: some View {
        let planet = DGMPlanet.testPlanet()
        planet.run()
        let factory = planet.facilities.first{$0 is DGMFactory} as? DGMFactory
        return NavigationView {
            List {
                FactorySection(factory: factory!)
            }.listStyle(GroupedListStyle())
        }.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(planet)
    }
}
