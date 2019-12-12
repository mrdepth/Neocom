//
//  TypeMarketOrderCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/12/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible

struct TypeMarketOrderCell: View {
    var order: TypeMarketOrders.Row
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("1000 ISK")
                Spacer()
                Text("Quantity:")
                Text("1000")
            }
            order.location.map{Text($0)} ?? Text("Unknown Location")
        }
    }
}

struct TypeMarketOrderCell_Previews: PreviewProvider {
    static var previews: some View {
        TypeMarketOrderCell(order: try! TypeMarketOrders.Row(order: ESI.TypeMarketOrder(duration: 1, isBuyOrder: true, issued: Date(), locationID: 0, minVolume: 0, orderID: 0, price: 1000, range: .i1, systemID: 0, typeID: 645, volumeRemain: 0, volumeTotal: 0), location: EVELocation(AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEStaStation.self).first()!)))
    }
}
