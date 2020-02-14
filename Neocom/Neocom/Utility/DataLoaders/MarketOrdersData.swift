//
//  MarketOrdersData.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Combine
import Alamofire
import CoreData

class MarketOrdersData: ObservableObject {
    @Published var result: Result<(byu: ESI.MarketOrders, sell: ESI.MarketOrders, locations: [Int64: EVELocation]), AFError>?
    
    init(esi: ESI, characterID: Int64, managedObjectContext: NSManagedObjectContext) {
        esi.characters.characterID(Int(characterID)).orders().get().flatMap { orders -> AnyPublisher<(ESI.MarketOrders, ESI.MarketOrders, [Int64: EVELocation]), AFError> in
            let locationIDs = orders.value.map{$0.locationID} + orders.value.map{Int64($0.regionID)}
            let locations = EVELocation.locations(with: Set(locationIDs), esi: esi, managedObjectContext: managedObjectContext).replaceError(with: [:])
            
            var tmp = orders.value.map{($0.issued + TimeInterval($0.duration * 3600 * 24), $0)}
            let i = tmp.partition{$0.1.isBuyOrder == true}
            let buy = tmp[i...].sorted{$0.0 < $1.0}.map{$0.1}
            let sell = tmp[..<i].sorted{$0.0 < $1.0}.map{$0.1}

            return Publishers.Zip3(Just(buy), Just(sell), locations).setFailureType(to: AFError.self).eraseToAnyPublisher()
        }.asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.result = result.map{(byu: $0.0, sell: $0.1, locations: $0.2)}
        }.store(in: &subscriptions)
    }
    
    var subscriptions = Set<AnyCancellable>()
}
