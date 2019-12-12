//
//  TypeMarketOrders.swift
//  Neocom
//
//  Created by Artem Shimanski on 12.12.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct TypeMarketOrders: View {
	
	enum Mode {
		case sell
		case buy
	}

	var type: SDEInvType

	@ObservedObject var marketOrders = Lazy<TypeMarketData>()
	@Environment(\.managedObjectContext) var managedObjectContext
	@Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
    @Environment(\.esi) var esi

	@UserDefault(key: .marketRegionID)
    var marketRegionID: Int = SDERegionID.default.rawValue
	
	@State var mode = Mode.sell
	
	private var regionName: String {
		(try? managedObjectContext.from(SDEMapRegion.self).filter(\SDEMapRegion.regionID == marketRegionID).first()?.regionName) ?? NSLocalizedString("Unknown", comment: "")
	}

    var body: some View {
		let orders = marketOrders.get(initial: TypeMarketData(type: type, esi: esi, regionID: marketRegionID, managedObjectContext: backgroundManagedObjectContext))
		let error = orders.result?.error
		let data = orders.result?.value

		return List {
			Section(header:
				Picker(selection: $mode, label: Text("Filter")) {
					Text("Sellers").tag(Mode.sell)
					Text("Buyers").tag(Mode.buy)
				}.pickerStyle(SegmentedPickerStyle())) {
					if data != nil {
						ForEach(mode == .sell ? data!.sellOrders : data!.buyOrders) { order in
							TypeMarketOrderCell(order: order)
						}
					}
			}
		}.listStyle(GroupedListStyle()).overlay(error.map{Text($0).padding()})
		.navigationBarTitle("Market Orders")
		.navigationBarItems(trailing: NavigationLink(regionName, destination: Text("dummy")))

    }
}

struct TypeMarketOrders_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			TypeMarketOrders(type: try! AppDelegate.sharedDelegate.persistentContainer.viewContext.fetch(SDEInvType.dominix()).first!)
				.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
				.environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext.newBackgroundContext())
		}
    }
}
