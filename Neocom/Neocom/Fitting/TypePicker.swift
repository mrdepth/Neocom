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
    
    var category: SDEDgmppItemCategory
    var parentGroup: SDEDgmppItemGroup?
    var completion: (SDEInvType) -> Void
    
    var body: some View {
        let group = try? parentGroup ?? managedObjectContext.from(SDEDgmppItemGroup.self).filter(/\SDEDgmppItemGroup.category == category && /\SDEDgmppItemGroup.parentGroup == nil).first()
        
        return group.map { group in
            
            TypePickerPage(category: category,
                           currentState: sequence(first: state.current ?? TypePickerState.Node(group)){$0.previous}.reversed().first!,
                           completion: completion)
        }
    }
}

struct TypePickerPage: View {
    var category: SDEDgmppItemCategory
    var completion: (SDEInvType) -> Void

    @EnvironmentObject private var state: TypePickerState
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var selectedGroup: SDEDgmppItemGroup?
    @State private var nextState: TypePickerState.Node?
    private var currentState: TypePickerState.Node
    
    init(category: SDEDgmppItemCategory, currentState: TypePickerState.Node, completion: @escaping (SDEInvType) -> Void) {
        self.currentState = currentState
        self.category = category
        self.completion = completion
        _selectedGroup = State(initialValue: currentState.next?.parentGroup)
        _nextState = State(initialValue: currentState.next)
    }

    
    var body: some View {
        Group {
            if (currentState.parentGroup.subGroups?.count ?? 0) > 0 {
                TypePickerGroups(category: category, currentState: currentState, completion: completion, selectedGroup: $selectedGroup)
            }
            else {
                TypePickerTypes(currentState: currentState, completion: completion)
            }
        }.onAppear {
            self.state.current = self.currentState
            self.currentState.previous?.next = self.currentState
            self.nextState = nil
        }
    }
}

struct TypePicker_Previews: PreviewProvider {
    static var previews: some View {
        let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
        let category = try! context.fetch(SDEDgmppItemCategory.category(categoryID: .ship)).first!
        return NavigationView {
            TypePicker(category: category) { _ in
                
            }
        }
            .environment(\.managedObjectContext, context)
    }
}
