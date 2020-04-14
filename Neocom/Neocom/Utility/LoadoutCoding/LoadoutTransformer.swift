//
//  LoadoutTransformer.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/7/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation

class LoadoutTransformer: ValueTransformer {
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let ship = value as? Ship else {return nil}
        return try? JSONEncoder().encode(ship)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {return nil}
        return try? JSONDecoder().decode(Ship.self, from: data)
    }
}
