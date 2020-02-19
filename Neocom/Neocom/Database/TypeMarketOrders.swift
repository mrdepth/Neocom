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
	@Environment(\.self) var environment

    @ObservedObject private var marketRegionID = UserDefault(wrappedValue: SDERegionID.default.rawValue,
                                                       key: .marketRegionID)

	@State private var mode = Mode.sell
	@State private var isMarketRegionPickerPresented = false
    
	private var regionName: String {
        (try? managedObjectContext.from(SDEMapRegion.self).filter(Expressions.keyPath(\SDEMapRegion.regionID) == Int32(marketRegionID.wrappedValue)).first()?.regionName) ?? NSLocalizedString("Unknown", comment: "")
	}

    var body: some View {
        let orders = marketOrders.get(initial: TypeMarketData(type: type, esi: esi, regionID: Int(marketRegionID.wrappedValue), managedObjectContext: backgroundManagedObjectContext))
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
            .overlay(orders.result == nil ? ActivityIndicator(style: .large) : nil)
            .overlay((orders.result?.error).map{Text($0)})
			.sheet(isPresented: $isMarketRegionPickerPresented) {
				NavigationView {
					MarketRegionPicker { region in
                        self.marketRegionID.wrappedValue = region.regionID
//						self.marketOrders.set(TypeMarketData(type: self.type, esi: self.esi, regionID: self.marketRegionID, managedObjectContext: self.backgroundManagedObjectContext))
						self.isMarketRegionPickerPresented = false
					}.navigationBarItems(trailing: Button("Cancel") {self.isMarketRegionPickerPresented = false})
				}.modifier(ServicesViewModifier(environment: self.environment))
        }
    }
}

struct TypeMarketOrders_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			TypeMarketOrders(type: .dominix)
				.environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
				.environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext.newBackgroundContext())
		}
    }
}
