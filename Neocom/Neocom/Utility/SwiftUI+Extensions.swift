//
//  SwiftUI+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 16.12.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData

struct ServicesViewModifier: ViewModifier {
    var managedObjectContext: NSManagedObjectContext
    var backgroundManagedObjectContext: NSManagedObjectContext
    var sharedState: SharedState
    
    init(environment: EnvironmentValues, sharedState: SharedState) {
        self.managedObjectContext = environment.managedObjectContext
        self.backgroundManagedObjectContext = environment.backgroundManagedObjectContext
        self.sharedState = sharedState
    }
    
    init(managedObjectContext: NSManagedObjectContext, backgroundManagedObjectContext: NSManagedObjectContext, sharedState: SharedState) {
        self.managedObjectContext = managedObjectContext
        self.backgroundManagedObjectContext = backgroundManagedObjectContext
        self.sharedState = sharedState
    }
    

    func body(content: Content) -> some View {
		content.environment(\.managedObjectContext, managedObjectContext)
			.environment(\.backgroundManagedObjectContext, backgroundManagedObjectContext)
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

extension Binding {
    init<T: AnyObject>(_ object: T, keyPath: WritableKeyPath<T, Value>) {
        var object = object
        self.init(get: {
            object[keyPath: keyPath]
        }) {object[keyPath: keyPath] = $0}
    }
}

enum OpenMode {
    case `default`
    case currentWindow
    case newWindow
    
    var openInNewWindow: Bool {
        switch self {
        case .default:
            #if targetEnvironment(macCatalyst)
            return true
            #else
            return false
            #endif
        case .newWindow:
            return true
        case .currentWindow:
            return false
        }

    }
}
