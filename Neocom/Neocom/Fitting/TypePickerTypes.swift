//
//  TypePickerTypes.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/25/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import CoreData

struct TypePickerTypes: View {
    var currentState: TypePickerState.Node
    var completion: (SDEInvType) -> Void
    @State private var selectedType: SDEInvType?
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    
    var predicate: PredicateProtocol {
        (/\SDEInvType.dgmppItem?.groups).contains(currentState.parentGroup)
    }
    
    private func types() -> FetchedResultsController<SDEInvType> {
        Types.fetchResults(with: predicate, managedObjectContext: managedObjectContext)
    }

    var body: some View {
        ObservedObjectView(self.types()) { types in
            TypesSearch(searchString: self.currentState.searchString ?? "", predicate: self.predicate, onUpdated: {self.currentState.searchString = $0}) { searchResults in
                List {
                    TypePickerTypesContent(types: searchResults ?? types.sections, selectedType: self.$selectedType, completion: self.completion)
                }.listStyle(GroupedListStyle())
                    .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }
        }.navigationBarTitle(currentState.parentGroup.groupName ?? "")
        .sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }.modifier(ServicesViewModifier(environment: self.environment))
        }

    }
}

struct TypePickerTypesContent: View {
    var types: [FetchedResultsController<SDEInvType>.Section]
    @Binding var selectedType: SDEInvType?
    var completion: (SDEInvType) -> Void
    
    var body: some View {
        TypesContent(types: types) { type in
            HStack(spacing: 0) {
                Button(action: {self.completion(type)}) {
                    HStack(spacing: 0) {
                        TypeCell(type: type)
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
                InfoButton {
                    self.selectedType = type
                }
            }
        }
    }
}


struct TypePickerTypes_Previews: PreviewProvider {
    static var previews: some View {
        let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
        let group = try? context.from(SDEDgmppItemGroup.self)
            .filter((/\SDEDgmppItemGroup.items).count > 0)
            .first()
        
        return TypePickerTypes(currentState: TypePickerState.Node(group!)) { _ in }
            .environment(\.managedObjectContext, context)
    }
}
