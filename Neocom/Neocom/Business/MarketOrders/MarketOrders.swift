//
//  MarketOrders.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI

struct MarketOrders: View {
    private enum Filter {
        case sell
        case buy
    }
    @State private var filter = Filter.sell
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState

    @ObservedObject var orders: Lazy<MarketOrdersData, Account> = Lazy()

    private var picker: some View {
        Picker("Filter", selection: $filter) {
            Text("Sell").tag(Filter.sell)
            Text("Buy").tag(Filter.buy)
        }.pickerStyle(SegmentedPickerStyle())
    }
    
    var body: some View {
        let result = sharedState.account.map { account in
            self.orders.get(account, initial: MarketOrdersData(esi: sharedState.esi, characterID: account.characterID, managedObjectContext: managedObjectContext))
        }
        
        let orders = filter == .buy ? result?.result?.value?.byu : result?.result?.value?.sell
        
        
        
        let list = List {
            Section(header: picker) {
                if orders != nil {
                    MarketOrdersContent(orders: orders!, locations: result?.result?.value?.locations ?? [:])
                }
            }
        }.listStyle(GroupedListStyle())
            .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay((result?.result?.error).map{Text($0)})
            .overlay(orders?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
        
        return Group {
            if result != nil {
                list.onRefresh(isRefreshing: Binding(result!, keyPath: \.isLoading)) {
                    result?.update(cachePolicy: .reloadIgnoringLocalCacheData)
                }
            }
            else {
                list
            }
        }
        .navigationBarTitle(Text("Market Orders"))

    }
}

struct MarketOrdersContent: View {
    var orders: ESI.MarketOrders
    var locations: [Int64: EVELocation]
    
    var body: some View {
        ForEach(orders, id: \.orderID) { order in
            MarketOrderCell(order: order, locations: self.locations)
        }
    }
}

#if DEBUG
struct MarketOrders_Previews: PreviewProvider {
    static var previews: some View {
        let solarSystem = try! AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEMapSolarSystem.self).first()!
        let location = EVELocation(solarSystem: solarSystem, id: Int64(solarSystem.solarSystemID))
        
        let orders = (0..<100).map { i in
            ESI.MarketOrders.Element(duration: 3,
                                     escrow: 1000,
                                     isBuyOrder: true,
                                     isCorporation: false,
                                     issued: Date(timeIntervalSinceNow: -3600 * TimeInterval(i) * 3),
                                     locationID: location.id,
                                     minVolume: 10,
                                     orderID: 1,
                                     price: 1e6,
                                     range: .solarsystem,
                                     regionID: Int(solarSystem.constellation!.region!.regionID),
                                     typeID: 645,
                                     volumeRemain: 3,
                                     volumeTotal: 20)
        }

        return NavigationView {
            MarketOrders()
//            List {
//                MarketOrdersContent(orders: orders, locations: [location.id: location])
//            }.listStyle(GroupedListStyle())
//                .navigationBarTitle(Text("Market Orders"))
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(SharedState.testState())
    }
}
#endif
