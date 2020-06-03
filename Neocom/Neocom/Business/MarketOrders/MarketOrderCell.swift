//
//  MarketOrderCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible
import CoreData

struct MarketOrderCell: View {
    var order: ESI.MarketOrders.Element
    var locations: [Int64: EVELocation]
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    func content(_ type: SDEInvType?) -> some View {
        let expired = order.issued + TimeInterval(order.duration * 3600 * 24)
        let t = expired.timeIntervalSinceNow
        
        return VStack(alignment: .leading) {
            HStack {
                type.map{Icon($0.image).cornerRadius(4)}
                VStack(alignment: .leading) {
                    (type?.typeName).map {Text($0)} ?? Text("Unknown Type")
                    Text(locations[order.locationID] ?? locations[Int64(order.regionID)] ?? .unknown(order.locationID)).modifier(SecondaryLabelModifier())
                }
            }
            HStack {
                VStack(alignment: .leading) {
                    Text("Open:").fontWeight(.semibold)
                    Text("Price:").fontWeight(.semibold)
                    Text("Updated:").fontWeight(.semibold)
                }.foregroundColor(.primary)
                VStack(alignment: .leading) {
                    Text("Expires in \(TimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes))")
                    Text(UnitFormatter.localizedString(from: order.price, unit: .isk, style: .long))
                    Text(DateFormatter.localizedString(from: order.issued, dateStyle: .medium, timeStyle: .medium))
                }
                Text("Qty:").fontWeight(.semibold).foregroundColor(.primary)
                Text(UnitFormatter.localizedString(from: order.volumeRemain, unit: .none, style: .long) + "/" + UnitFormatter.localizedString(from: order.volumeTotal, unit: .none, style: .long))
            }.modifier(SecondaryLabelModifier())
        }
    }
    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(order.typeID)).first()
        return Group {
            if type != nil {
                NavigationLink(destination: TypeInfo(type: type!)) {
                    content(type)
                }
            }
            else {
                content(nil)
            }
        }
    }
}

struct MarketOrderCell_Previews: PreviewProvider {
    static var previews: some View {
        let solarSystem = try! Storage.sharedStorage.persistentContainer.viewContext.from(SDEMapSolarSystem.self).first()!
        let location = EVELocation(solarSystem: solarSystem, id: Int64(solarSystem.solarSystemID))

        let order = ESI.MarketOrders.Element(duration: 3,
                                             escrow: 1000,
                                             isBuyOrder: true,
                                             isCorporation: false,
                                             issued: Date(timeIntervalSinceNow: -3600),
                                             locationID: location.id,
                                             minVolume: 10,
                                             orderID: 1,
                                             price: 1e6,
                                             range: .solarsystem,
                                             regionID: Int(solarSystem.constellation!.region!.regionID),
                                             typeID: 645,
                                             volumeRemain: 3,
                                             volumeTotal: 20)
        
        return NavigationView {
            List {
                MarketOrderCell(order: order, locations: [location.id: location])
            }.listStyle(GroupedListStyle())
        }.environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
