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
//	@State var orders = Cache<Int, TypeMarketData>()
	@Environment(\.managedObjectContext) var managedObjectContext
	@Environment(\.backgroundManagedObjectContext) var backgroundManagedObjectContext
    @Environment(\.esi) var esi
	@Environment(\.self) var environment

	@UserDefault(key: .marketRegionID)
    var marketRegionID: Int = SDERegionID.default.rawValue
	
	@State private var mode = Mode.sell
	@State private var isMarketRegionPickerPresented = false
	
	private var regionName: String {
		(try? managedObjectContext.from(SDEMapRegion.self).filter(\SDEMapRegion.regionID == marketRegionID).first()?.regionName) ?? NSLocalizedString("Unknown", comment: "")
	}

    var body: some View {
//		let orders = self.orders[marketRegionID, default: TypeMarketData(type: type, esi: esi, regionID: marketRegionID, managedObjectContext: backgroundManagedObjectContext)]
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
			.navigationBarItems(trailing: Button(regionName) {self.isMarketRegionPickerPresented = true})
			.sheet(isPresented: $isMarketRegionPickerPresented) {
				NavigationView {
					MarketRegionPicker { region in
						self.marketRegionID = Int(region.regionID)
						self.marketOrders.set(TypeMarketData(type: self.type, esi: self.esi, regionID: self.marketRegionID, managedObjectContext: self.backgroundManagedObjectContext))
						self.isMarketRegionPickerPresented = false
					}.navigationBarItems(trailing: Button("Cancel") {self.isMarketRegionPickerPresented = false})
				}.modifier(ServicesViewModifier(environment: self.environment))
		}
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
