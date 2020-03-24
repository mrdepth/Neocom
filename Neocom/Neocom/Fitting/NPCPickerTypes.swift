//
//  NPCPickerTypes.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import CoreData

struct NPCPickerTypes: View {
    var parent: SDENpcGroup
    var completion: (SDEInvType) -> Void
    @State private var selectedType: SDEInvType?
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    
    var predicate: PredicateProtocol {
        /\SDEInvType.group == parent.group
    }
    
    private func types() -> FetchedResultsController<SDEInvType> {
        Types.fetchResults(with: predicate, managedObjectContext: managedObjectContext)
    }

    var body: some View {
        ObservedObjectView(self.types()) { types in
            List {
                TypePickerTypesContent(types: types.sections, selectedType: self.$selectedType, completion: self.completion)
            }.listStyle(GroupedListStyle())
        }.navigationBarTitle(parent.group?.groupName ?? "")
        .sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }.modifier(ServicesViewModifier(environment: self.environment))
        }

    }
}

struct NPCPickerTypes_Previews: PreviewProvider {
    static var previews: some View {
        let context = AppDelegate.sharedDelegate.persistentContainer.viewContext
        let group = try? context.from(SDENpcGroup.self).filter((/\SDENpcGroup.group) != nil).first()
        return NPCPickerTypes(parent: group!) { _ in }
            .environment(\.managedObjectContext, context)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
    }
}
