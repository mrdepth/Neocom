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
    var order: TypeMarketData.Row
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
				Text(UnitFormatter.localizedString(from: order.order.price, unit: .isk, style: .long))
				Spacer()
                Text("Quantity:")
				Text(UnitFormatter.localizedString(from: order.order.volumeRemain, unit: .none, style: .long))
			}
			(order.location.map{Text($0)} ?? Text("Unknown Location")).font(.footnote)
        }
    }
}

struct TypeMarketOrderCell_Previews: PreviewProvider {
    static var previews: some View {
		List {
        TypeMarketOrderCell(order: try! TypeMarketData.Row(order: ESI.TypeMarketOrder(duration: 1, isBuyOrder: true, issued: Date(), locationID: 0, minVolume: 0, orderID: 0, price: 1000, range: .i1, systemID: 0, typeID: 645, volumeRemain: 0, volumeTotal: 0), location: EVELocation(AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEStaStation.self).first()!)))
		}.listStyle(GroupedListStyle())
    }
}
