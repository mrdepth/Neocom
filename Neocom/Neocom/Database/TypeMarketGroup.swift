//
//  TypeMarketGroup.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/23/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import CoreData

struct TypeMarketGroup: View {
    var parent: SDEInvMarketGroup?
    @Environment(\.managedObjectContext) var managedObjectContext

    private func getMarketGroups() -> FetchedResultsController<SDEInvMarketGroup> {
        let controller = managedObjectContext.from(SDEInvMarketGroup.self)
            .filter(/\SDEInvMarketGroup.parentGroup == parent)
            .sort(by: \SDEInvMarketGroup.marketGroupName, ascending: true)
            .fetchedResultsController()
        return FetchedResultsController(controller)
    }

    private let marketGroups = Lazy<FetchedResultsController<SDEInvMarketGroup>, Never>()
    
    @State private var searchString: String = ""
    @State private var searchResults: [FetchedResultsController<SDEInvType>.Section]? = nil

    var body: some View {
        let marketGroups = self.marketGroups.get(initial: getMarketGroups())
        let predicate = /\SDEInvType.marketGroup != nil
        
        return TypesSearch(predicate: predicate, searchString: $searchString, searchResults: $searchResults) {
            if self.searchResults != nil {
                TypesContent(types: self.searchResults!) { type in
                    NavigationLink(destination: TypeInfo(type: type)) {
                        TypeCell(type: type)
                    }
                }
            }
            else {
                TypeMarketGroupContent(marketGroups: marketGroups)
            }
        }
        .navigationBarTitle(parent?.marketGroupName ?? NSLocalizedString("Market", comment: ""))
    }
}

struct TypeMarketGroupContent: View {
    var marketGroups: FetchedResultsController<SDEInvMarketGroup>
    
    private func content(for marketGroup: SDEInvMarketGroup) -> some View {
        HStack {
            Icon(marketGroup.image)
            Text(marketGroup.marketGroupName ?? "")
        }
    }
    
    private func row(for marketGroup: SDEInvMarketGroup) -> some View {
        Group {
            if (marketGroup.subGroups?.count ?? 0) > 0 {
                NavigationLink(destination: TypeMarketGroup(parent: marketGroup)) {
                    self.content(for: marketGroup)
                }
            }
            else {
                NavigationLink(destination: Types(.marketGroup(marketGroup))) {
                    self.content(for: marketGroup)
                }
            }
        }
    }

    var body: some View {
        ForEach(marketGroups.fetchedObjects, id: \.objectID) { marketGroup in
            self.row(for: marketGroup)
        }
    }
}

struct TypeMarketGroup_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TypeMarketGroup().environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        }
    }
}
