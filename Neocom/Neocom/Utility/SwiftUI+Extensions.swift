//
//  SwiftUI+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 16.12.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI


struct ServicesViewModifier: ViewModifier {
	var environment: EnvironmentValues

	func body(content: Content) -> some View {
		content.environment(\.managedObjectContext, environment.managedObjectContext)
			.environment(\.backgroundManagedObjectContext, environment.backgroundManagedObjectContext)
			.environment(\.esi, environment.esi)
			.environment(\.account, environment.account)
	}
}

//struct BlockModifier<Result: View>: ViewModifier {
//    var block: (Content) -> Result
//    init(@ViewBuilder _ block: @escaping (Content) -> Result) {
//        self.block = block
//    }
//    
//    func body(content: Content) -> Result {
//        block(content)
//    }
//
//}

struct SecondaryLabelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.caption).foregroundColor(.secondary)
    }
}

class IdentifiableWrapper<Value>: Identifiable {
    var wrappedValue: Value
    init(_ value: Value) {
        wrappedValue = value
    }
}

extension Font {
    static let title2 = Font(UIFont.preferredFont(forTextStyle: .title2))
}


extension View {
    /**Append preference AppendPreferenceKey<CGSize, ID>*/
    func sizePreference<ID>(_ id: ID.Type = ID.self) -> some View {
        self.background(GeometryReader { geometry in
            Color.clear.preference(key: AppendPreferenceKey<CGSize, ID>.self, value: [geometry.size])
        })
    }
    
    func onSizeChange<ID>(_ id: ID.Type = ID.self, perform action: @escaping (AppendPreferenceKey<CGSize, ID>.Value) -> Void) -> some View {
        onPreferenceChange(AppendPreferenceKey<CGSize, ID>.self, perform: action)
    }
}


