//
//  TypePicker.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import CoreData

class TypePickerManager {
    private let typePickerState = Cache<SDEDgmppItemGroup, TypePickerState>()
    func get(_ parentGroup: SDEDgmppItemGroup, environment: EnvironmentValues, sharedState: SharedState, completion: @escaping (SDEInvType?) -> Void) -> some View {
        NavigationView {
            TypePicker(parentGroup: parentGroup) {
                completion($0)
            }
            .navigationBarItems(leading: BarButtonItems.close {
                completion(nil)
            })
        }
        .modifier(ServicesViewModifier(environment: environment, sharedState: sharedState))
        .environmentObject(typePickerState[parentGroup, default: TypePickerState()])
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

class TypePickerState: ObservableObject {
    class Node: ObservableObject {
        var parentGroup: SDEDgmppItemGroup
        var previous: Node?
        var searchString: String?
        weak var next: Node?
        
        init(_ parentGroup: SDEDgmppItemGroup, previous: Node? = nil) {
            self.parentGroup = parentGroup
            self.previous = previous
        }
    }
    
    var current: Node?
}

struct TypePicker: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var state: TypePickerState
    
    var parentGroup: SDEDgmppItemGroup
    var completion: (SDEInvType) -> Void
    
    init(parentGroup: SDEDgmppItemGroup, completion: @escaping (SDEInvType) -> Void) {
        self.parentGroup = parentGroup
        self.completion = completion
    }
    
    var body: some View {
        TypePickerPage(currentState: sequence(first: state.current ?? TypePickerState.Node(parentGroup)){$0.previous}.reversed().first!,
                       completion: completion)
    }
}

struct TypePickerPage: View {
    var completion: (SDEInvType) -> Void

    @EnvironmentObject private var state: TypePickerState
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var selectedGroup: SDEDgmppItemGroup?
    @State private var nextState: TypePickerState.Node?
    private var currentState: TypePickerState.Node
    
    init(currentState: TypePickerState.Node, completion: @escaping (SDEInvType) -> Void) {
        self.currentState = currentState
        self.completion = completion
        _selectedGroup = State(initialValue: currentState.next?.parentGroup)
        _nextState = State(initialValue: currentState.next)
    }

    
    var body: some View {
        Group {
            if (currentState.parentGroup.subGroups?.count ?? 0) > 0 {
                TypePickerGroups(currentState: currentState, completion: completion, selectedGroup: $selectedGroup)
            }
            else {
                TypePickerTypes(currentState: currentState, completion: completion)
            }
        }.onAppear {
            DispatchQueue.main.async {
                self.state.current = self.currentState
                self.currentState.previous?.next = self.currentState
                self.nextState = nil
            }
        }
    }
}

struct TypePicker_Previews: PreviewProvider {
    static var previews: some View {
        let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
        let group = try! context.fetch(SDEDgmppItemGroup.rootGroup(categoryID: .ship)).first!
        return NavigationView {
            TypePicker(parentGroup: group) { _ in
                
            }
        }
            .environment(\.managedObjectContext, context)
    }
}
