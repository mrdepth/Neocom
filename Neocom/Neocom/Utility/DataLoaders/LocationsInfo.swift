//
//  LocationsInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/11/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import CoreData

class LocationsInfo: ObservableObject {
    
    init(locationIDs: [Int64], esi: ESI, managedObjectContext: NSManagedObjectContext) {
        Future { promise in
            managedObjectContext.perform {
                
            }
        }
    }
}
