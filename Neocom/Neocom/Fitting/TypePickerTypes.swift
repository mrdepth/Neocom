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
    @ObservedObject var searchHelper: TypePickerSearchHelper
    var completion: (SDEInvType) -> Void
    @State private var selectedType: SDEInvType?
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    
    var predicate: PredicateProtocol {
        (/\SDEInvType.dgmppItem?.groups).contains(parentGroup)
    }
    
    private func getTypes() -> FetchedResultsController<SDEInvType> {
        Types.fetchResults(with: predicate, managedObjectContext: managedObjectContext)
    }

    private let types = Lazy<FetchedResultsController<SDEInvType>, Never>()
    
    
    var body: some View {
        let types = self.types.get(initial: getTypes())
        
        return TypesSearch(predicate: self.predicate, searchString:$searchHelper.searchString, searchResults: $searchHelper.searchResults) {
            TypePickerTypesContent(types: self.searchHelper.searchResults ?? types.sections, selectedType: self.$selectedType, completion: self.completion)
        }
        .navigationBarTitle(parentGroup.groupName ?? "")
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
        let context = Storage.testStorage.persistentContainer.viewContext
        let group = try? context.from(SDEDgmppItemGroup.self)
            .filter((/\SDEDgmppItemGroup.items).count > 0)
            .first()
        
        return TypePickerTypes(parentGroup: group!, searchHelper: TypePickerSearchHelper()) { _ in }
            .modifier(ServicesViewModifier.testModifier())
    }
}
