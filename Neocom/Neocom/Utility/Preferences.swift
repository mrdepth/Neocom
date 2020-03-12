//
//  Preferences.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.12.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

struct AppendPreferenceKey<Element: Equatable, ID>: PreferenceKey {
    static var defaultValue: Value { [] }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
    typealias Value = [Element]
}

//struct SizePreferenceKey: PreferenceKey {
//    static var defaultValue: Value = []
//
//    static func reduce(value: inout Value, nextValue: () -> Value) {
//        value += nextValue()
//    }
//
//    typealias Value = [CGSize]
//}

struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: Value = []
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
    
    typealias Value = [CGRect]
}
