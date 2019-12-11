//
//  TypeMarketOrders.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/11/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import CoreData

class TypeMarketOrders: ObservableObject {
    
    init(type: SDEInvType, esi: ESI, regionID: Int, managedObjectContext: NSManagedObjectContext) {
        esi.markets.regionID(regionID).orders().get(typeID: Int(type.typeID))
    }
}
