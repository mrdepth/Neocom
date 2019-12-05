//
//  ObservedObjectView.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/27/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData

struct ObservedObjectView<Content: View, Value: ObservableObject>: View {
    @ObservedObject var value: Value
    var content: (Value) -> Content
    
    @inlinable init(_ value: Value, content: @escaping (Value) -> Content) {
        self.value = value
        self.content = content
    }
    
    var body: some View {
        content(value)
    }
}
