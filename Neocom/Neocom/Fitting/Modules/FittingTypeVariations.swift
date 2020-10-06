//
//  FittingTypeVariations.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/28/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import CoreData
import Expressible

struct FittingTypeVariations: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @State private var selectedType: SDEInvType?
    @EnvironmentObject private var sharedState: SharedState

    var type: SDEInvType
    var completion: (SDEInvType) -> Void

    private func types() -> FetchedResultsController<SDEInvType> {
        let what = type.parentType ?? type
        let predicate = /\SDEInvType.parentType == what || /\SDEInvType.self == what
        return Types.fetchResults(with: predicate, managedObjectContext: managedObjectContext)
    }
    

    var body: some View {
        ObservedObjectView(types()) { types in
            List {
                TypePickerTypesContent(types: types.sections, selectedType: self.$selectedType, completion: self.completion)
            }.listStyle(GroupedListStyle())
        }
        .navigationBarTitle(Text("Variations"))
        .sheet(item: $selectedType) { type in
            NavigationView {
                TypeInfo(type: type).navigationBarItems(leading: BarButtonItems.close {self.selectedType = nil})
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct FittingTypeVariations_Previews: PreviewProvider {
    static var previews: some View {
        let type = try! Storage.testStorage.persistentContainer.viewContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == 3154).first()!
        return NavigationView {
            FittingTypeVariations(type: type) {_ in}
        }
        .modifier(ServicesViewModifier.testModifier())
    }
}


