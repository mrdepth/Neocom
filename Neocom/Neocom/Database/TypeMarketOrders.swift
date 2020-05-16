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

	@ObservedObject var marketOrders = Lazy<TypeMarketData, Never>()
	@Environment(\.managedObjectContext) private var managedObjectContext
	@Environment(\.backgroundManagedObjectContext) private var backgroundManagedObjectContext
    @EnvironmentObject private var sharedState: SharedState
	@Environment(\.self) var environment

    @ObservedObject private var marketRegionID = UserDefault(wrappedValue: SDERegionID.default.rawValue,
                                                       key: .marketRegionID)

	@State private var mode = Mode.sell
	@State private var isMarketRegionPickerPresented = false
    
	private var regionName: String {
        (try? managedObjectContext.from(SDEMapRegion.self).filter(/\SDEMapRegion.regionID == Int32(marketRegionID.wrappedValue)).first()?.regionName) ?? NSLocalizedString("Unknown", comment: "")
	}

    var body: some View {
        let result = marketOrders.get(initial: TypeMarketData(type: type, esi: sharedState.esi, regionID: Int(marketRegionID.wrappedValue), managedObjectContext: backgroundManagedObjectContext))
		let error = result.result?.error
		let data = result.result?.value

		return List {
			Section(header:
                Picker("Filter", selection: $mode) {
					Text("Sellers").tag(Mode.sell)
					Text("Buyers").tag(Mode.buy)
				}.pickerStyle(SegmentedPickerStyle())) {
					if data != nil {
						ForEach(mode == .sell ? data!.sellOrders : data!.buyOrders) { order in
							TypeMarketOrderCell(order: order)
                        }
					}
			}
		}
        .listStyle(GroupedListStyle())
        .onRefresh(isRefreshing: Binding(result, keyPath: \.isLoading)) {
            result.update(cachePolicy: .reloadIgnoringLocalCacheData)
        }
        .overlay(error.map{Text($0).padding()})
        .overlay(result.result == nil ? ActivityIndicatorView(style: .large) : nil)
        .overlay((result.result?.error).map{Text($0)})
        .navigationBarTitle("Market Orders")
        .navigationBarItems(trailing: Button(regionName) {self.isMarketRegionPickerPresented = true})
        .sheet(isPresented: $isMarketRegionPickerPresented) {
            NavigationView {
                MarketRegionPicker { region in
                    self.marketRegionID.wrappedValue = region.regionID
                    //                        self.marketOrders.set(TypeMarketData(type: self.type, esi: self.esi, regionID: self.marketRegionID, managedObjectContext: self.backgroundManagedObjectContext))
                    self.isMarketRegionPickerPresented = false
                }.navigationBarItems(trailing: Button("Cancel") {self.isMarketRegionPickerPresented = false})
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }

    }
}

#if DEBUG
struct TypeMarketOrders_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			TypeMarketOrders(type: .dominix)
				.environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
				.environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.viewContext.newBackgroundContext())
		}
        .environmentObject(SharedState.testState())
    }
}
#endif
