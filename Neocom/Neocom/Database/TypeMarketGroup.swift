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

    private func marketGroups() -> FetchedResultsController<SDEInvMarketGroup> {
        let controller = managedObjectContext.from(SDEInvMarketGroup.self)
            .filter(\SDEInvMarketGroup.parentGroup == parent)
            .sort(by: \SDEInvMarketGroup.marketGroupName, ascending: true)
            .fetchedResultsController()
        return FetchedResultsController(controller)
    }

    var body: some View {
        ObservedObjectView(marketGroups()) { marketGroups in
            TypesSearch(predicate: \SDEInvType.marketGroup != nil) { searchResults in
                List {
                    if searchResults == nil {
                        TypeMarketGroupContent(marketGroups: marketGroups)
                    }
                    else {
                        TypesContent(types: searchResults!)
                    }
                }.listStyle(GroupedListStyle())
                    .overlay(searchResults?.isEmpty == true ? Text("No Results") : nil)
            }
        }.navigationBarTitle(parent?.marketGroupName ?? NSLocalizedString("Market", comment: ""))
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
            TypeMarketGroup().environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        }
    }
}
