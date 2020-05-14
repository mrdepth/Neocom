//
//  FittingCharges.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/28/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible

struct FittingCharges: View {
    var category: SDEDgmppItemCategory
    var completion: (SDEInvType) -> Void
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @State private var selectedType: SDEInvType?
    @EnvironmentObject private var sharedState: SharedState
    
    var predicate: PredicateProtocol {
        guard let parentGroup = try? managedObjectContext.from(SDEDgmppItemGroup.self).filter(/\SDEDgmppItemGroup.category == category && /\SDEDgmppItemGroup.parentGroup == nil).first() else {return Expressions.constant(false) == true}
        return (/\SDEInvType.dgmppItem?.groups).contains(parentGroup)
    }
    
    private func types() -> FetchedResultsController<SDEInvType> {
        Types.fetchResults(with: predicate, managedObjectContext: managedObjectContext)
    }

    
    var body: some View {
        ObservedObjectView(types()) { types in
            List {
                TypePickerTypesContent(types: types.sections, selectedType: self.$selectedType, completion: self.completion)
            }.listStyle(GroupedListStyle())
        }
        .navigationBarTitle("Charges")
        .sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct FittingCharges_Previews: PreviewProvider {
    static var previews: some View {
        let type = try! AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == 3154).first()!
        let charge = type.dgmppItem?.charge
        return NavigationView {
            FittingCharges(category: charge!) {_ in}
        }
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
