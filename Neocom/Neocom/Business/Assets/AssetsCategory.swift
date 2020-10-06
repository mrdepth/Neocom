//
//  AssetsCategory.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/11/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct AssetsCategory: View {
    var category: AssetsData.Category
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    private func cell(for type: AssetsData.Category.AssetType) -> some View {
        let invType = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(type.typeID)).first()
        let icon = invType?.image ?? (try? managedObjectContext.fetch(SDEEveIcon.named(.defaultType)).first?.image?.image).map{Image(uiImage: $0)}
        
        return NavigationLink(destination: AssetsCategoryLocations(assets: type.locations).navigationBarTitle(type.typeName)) {
            HStack {
                icon.map{Icon($0).cornerRadius(4)}
                VStack(alignment: .leading) {
                    (invType?.typeName).map{Text($0)} ?? Text("Unknown")
                    Text("Quantity: \(UnitFormatter.localizedString(from: type.count, unit: .none, style: .long))").modifier(SecondaryLabelModifier())
                }
            }
        }
    }
    
    
    var body: some View {
        List {
            ForEach(category.types, id: \.typeID) { type in
                self.cell(for: type)
            }
        }.navigationBarTitle(category.categoryName)
    }
}

fileprivate struct AssetsCategoryLocations: View {
    var assets: [AssetsData.LocationGroup]
    var body: some View {
        List {
            ForEach(assets, id: \.location.id) { i in
                Section(header: Text(i.location)) {
                    AssetsListContent(assets: i.assets)
                }
            }
        }.listStyle(GroupedListStyle())
    }
}

struct AssetsCategory_Previews: PreviewProvider {
    static var previews: some View {
        AssetsCategory(category: AssetsData.Category(categoryName: "Ships", id: 0, types: []))
            .modifier(ServicesViewModifier.testModifier())
    }
}
