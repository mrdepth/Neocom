//
//  LoyaltyOffersLoader.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/28/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import CoreData
import Alamofire
import Expressible

class LoyaltyOffersLoader: ObservableObject {
    @Published var result: Result<[Category], AFError>?
    private var subscription: AnyCancellable?
    
    struct Category: Identifiable {
        struct Group: Identifiable {
            struct Offer: Identifiable {
                var id: NSManagedObjectID
                var name: String
                var offer: ESI.LoyaltyOffers.Element
            }
            var id: NSManagedObjectID
            var name: String
            var types: [Offer]
        }
        var id: NSManagedObjectID
        var name: String
        var groups: [Group]
    }
    
    init(esi: ESI, corporationID: Int64, managedObjectContext: NSManagedObjectContext) {
        
        subscription = esi.loyalty.stores().corporationID(Int(corporationID)).offers().get()
            .map{$0.value}
            .receive(on: managedObjectContext)
            .map { result -> [Category] in
                let offers = Dictionary(result.map{($0.typeID, $0)}) {a, _ in a}
                
                let types = (try? managedObjectContext.from(SDEInvType.self).filter((/\SDEInvType.typeID).in(Set(offers.keys))).fetch()) ?? []
                let groups = Dictionary(grouping: types, by: {$0.group!})
                let categories = Dictionary(grouping: groups, by: {$0.key.category!})
                return categories.sorted{$0.key.categoryName! < $1.key.categoryName!}.map { category in
                    Category(id: category.key.objectID,
                             name: category.key.categoryName!,
                             groups: category.value.sorted{$0.key.groupName! < $1.key.groupName!}.map { group in
                                Category.Group(id: group.key.objectID,
                                               name: group.key.groupName!,
                                               types: group.value.sorted{$0.typeName! < $1.typeName!}.map{Category.Group.Offer(id: $0.objectID,
                                                                                                                               name: $0.typeName!,
                                                                                                                               offer: offers[Int($0.typeID)]!)})
                    })
                }
        }
        .asResult()
        .receive(on: RunLoop.main)
        .sink { [weak self] result in
            self?.result = result
        }

    }
}

