//
//  TypeMarketData.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/11/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import CoreData
import Alamofire

class TypeMarketData: ObservableObject {
    
    struct Row: Identifiable {
        var id: Int64 {order.orderID}
        var order: ESI.TypeMarketOrder
        var location: EVELocation?
    }
    
    struct Data {
        var buyOrders: [Row]
        var sellOrders: [Row]
    }
    
    @Published var result: Result<Data, AFError>?
    
    private var subscription: AnyCancellable?
    
    init(type: SDEInvType, esi: ESI, regionID: Int, managedObjectContext: NSManagedObjectContext) {
        subscription = esi.markets.regionID(regionID).orders().get(typeID: Int(type.typeID)).flatMap { orders in
            Publishers.Zip(Just(orders), EVELocation.locations(with: Set(orders.value.map{$0.locationID}), esi: esi, managedObjectContext: managedObjectContext))
                .setFailureType(to: AFError.self)
        }.map { (orders, locations) -> Data in
            var orders = orders
            let i = orders.value.partition { $0.isBuyOrder }
            let sell = orders.value[..<i].sorted{$0.price < $1.price}.map{Row(order: $0, location: locations[$0.locationID])}
            let buy = orders.value[i...].sorted{$0.price > $1.price}.map{Row(order: $0, location: locations[$0.locationID])}
            return Data(buyOrders: buy, sellOrders: sell)
        }.asResult().receive(on: RunLoop.main).sink { [weak self] result in
            self?.result = result
        }
    }
}
