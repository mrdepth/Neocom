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
    var parentGroup: SDEDgmppItemGroup
    var completion: (SDEInvType) -> Void
    @State private var selectedType: SDEInvType?
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    
    var predicate: PredicateProtocol {
        (/\SDEInvType.dgmppItem?.groups).contains(parentGroup)
    }
    
    private func types() -> FetchedResultsController<SDEInvType> {
        Types.fetchResults(with: predicate, managedObjectContext: managedObjectContext)
    }

    var body: some View {
        ObservedObjectView(self.types()) { types in
            TypesSearch(searchString: "", predicate: self.predicate, onUpdated: nil) { searchResults in
                List {
                    TypePickerTypesContent(types: searchResults ?? types.sections, selectedType: self.$selectedType, completion: self.completion)
                }.listStyle(GroupedListStyle())
                    .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }
        }.navigationBarTitle(parentGroup.groupName ?? "")
        .sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
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
        
        return TypePickerTypes(parentGroup: group!) { _ in }
            .environment(\.managedObjectContext, context)
    }
}
