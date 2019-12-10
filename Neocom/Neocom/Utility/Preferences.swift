//
//  Preferences.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.12.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: Value = []
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
    
    typealias Value = [CGSize]
}
