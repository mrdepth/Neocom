//
//  AssetCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/7/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible

struct AssetCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var asset: AssetsData.Asset
    
    private func content(_ type: SDEInvType?) -> some View {
        
        return HStack {
            type.map{Icon($0.image).cornerRadius(4)}
            VStack(alignment: .leading) {
                (type?.typeName).map{Text($0)} ?? Text("Unknown")
                if asset.underlyingAsset.quantity == 1 && asset.assetName != nil {
                    Text("\(asset.assetName!)").modifier(SecondaryLabelModifier())
                }
                else {
                    Text("Quantity: \(UnitFormatter.localizedString(from: asset.underlyingAsset.quantity, unit: .none, style: .long))").modifier(SecondaryLabelModifier())
                }
            }
        }
    }
    
    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(Expressions.keyPath(\SDEInvType.typeID) == Int32(asset.underlyingAsset.typeID)).first()
        
        return Group {
            if asset.nested.isEmpty {
                if type != nil {
                    NavigationLink(destination: TypeInfo(type: type!)) {
                        content(type)
                    }
                }
                else {
                    content(type)
                }
            }
            else {
                NavigationLink(destination: AssetsList(asset)) {
                    content(type)
                }
            }
        }
    }
}

struct AssetCell_Previews: PreviewProvider {
    static var previews: some View {
        let asset = AssetsData.Asset(nested: [], underlyingAsset: ESI.Assets.Element(isBlueprintCopy: nil, isSingleton: false, itemID: -1, locationFlag: .hangar, locationID: 0, locationType: .solarSystem, quantity: 1, typeID: 645), assetName: "Spyder" ,typeName: "Dominix", groupName: "Gellente Battleships", categoryName: "Ships", categoryID: 0)
        return List {
            AssetCell(asset: asset)
        }.listStyle(GroupedListStyle())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
