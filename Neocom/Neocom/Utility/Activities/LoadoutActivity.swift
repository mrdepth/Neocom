//
//  LoadoutActivity.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/8/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import UIKit

class LoadoutActivity: UIActivityItemProvider {
    let ship: Ship
    
    init(ship: Ship) {
        self.ship = ship
        super.init(placeholderItem: ship)
    }
    
    override var item: Any {
        (try? DNALoadoutEncoder().encode(ship)) ?? Data()
    }
}
