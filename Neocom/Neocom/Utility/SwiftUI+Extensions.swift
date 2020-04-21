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
    var sharedState: SharedState

    func body(content: Content) -> some View {
		content.environment(\.managedObjectContext, environment.managedObjectContext)
			.environment(\.backgroundManagedObjectContext, environment.backgroundManagedObjectContext)
            .environmentObject(sharedState)
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
    
    func framePreference<ID>(in coordinateSpace: CoordinateSpace, _ id: ID.Type = ID.self) -> some View {
        self.background(GeometryReader { geometry in
            Color.clear.preference(key: AppendPreferenceKey<CGRect, ID>.self, value: [geometry.frame(in: coordinateSpace)])
        })
    }
    
    func onFrameChange<ID>(_ id: ID.Type = ID.self, perform action: @escaping (AppendPreferenceKey<CGRect, ID>.Value) -> Void) -> some View {
        onPreferenceChange(AppendPreferenceKey<CGRect, ID>.self, perform: action)
    }
}


extension AnyTransition {
    static func repeating<T: ViewModifier>(from: T, to: T, duration: Double = 1) -> AnyTransition {
       .asymmetric(
            insertion: AnyTransition
                .modifier(active: from, identity: to)
                .animation(Animation.easeInOut(duration: duration).repeatForever())
                .combined(with: .opacity),
            removal: .opacity
        )
    }
}

struct Opacity: ViewModifier {
    private let opacity: Double
    init(_ opacity: Double) {
        self.opacity = opacity
    }

    func body(content: Content) -> some View {
        content.opacity(opacity)
    }
}
