//
//  TypePickerGroups.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/25/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible

class TypePickerSearchHelper: ObservableObject {
    @Published var searchString: String = ""
    @Published var searchResults: [FetchedResultsController<SDEInvType>.Section]? = nil
}

struct TypePickerGroups: View {
    var parentGroup: SDEDgmppItemGroup
    @ObservedObject var searchHelper: TypePickerSearchHelper
    var completion: (SDEInvType) -> Void
    @State private var selectedGroup: SDEDgmppItemGroup?
    @State private var selectedType: SDEInvType?
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    
    private func getGroups() -> FetchedResultsController<SDEDgmppItemGroup> {
        let controller = managedObjectContext.from(SDEDgmppItemGroup.self)
            .filter(/\SDEDgmppItemGroup.parentGroup == parentGroup)
            .sort(by: \SDEDgmppItemGroup.groupName, ascending: true)
            .fetchedResultsController()
        
        return FetchedResultsController(controller)
    }
    
    private var predicate: PredicateProtocol {
        (/\SDEInvType.dgmppItem?.groups).any(\SDEDgmppItemGroup.category) == parentGroup.category && /\SDEInvType.published == true
    }
    
    private func cell(_ type: SDEInvType) -> some View {
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
    
    private let groups = Lazy<FetchedResultsController<SDEDgmppItemGroup>, Never>()

    var body: some View {
        let groups = self.groups.get(initial: getGroups())
        
        return TypesSearch(predicate: self.predicate, searchString:$searchHelper.searchString, searchResults: $searchHelper.searchResults) {
            if self.searchHelper.searchResults != nil {
                TypePickerTypesContent(types: self.searchHelper.searchResults!, selectedType: self.$selectedType, completion: self.completion)
            }
            else {
                ForEach(groups.fetchedObjects, id: \.objectID) { group in
                    NavigationLink(destination: TypePickerPage(parentGroup: group, completion: self.completion),
                                   tag: group,
                                   selection: self.$selectedGroup) {
                                    HStack {
                                        Icon(group.image)
                                        Text(group.groupName ?? "")
                                    }
                    }
                }
            }
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

#if DEBUG
struct TypePickerGroups_Previews: PreviewProvider {
    static var previews: some View {
        let context = Storage.testStorage.persistentContainer.viewContext
        let group = try! context.fetch(SDEDgmppItemGroup.rootGroup(categoryID: .hi)).first!
        return NavigationView {
            TypePickerGroups(parentGroup: group,
                             searchHelper: TypePickerSearchHelper(),
                             completion: {_ in })
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
