//
//  AssetsList.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/7/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible

struct AssetsList: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var assets: [AssetsData.Asset]
    
    private func cell(for asset: AssetsData.Asset) -> some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(\SDEInvType.typeID == asset.underlyingAsset.typeID).first()
        return Group {
            if type?.typeName != nil {
                HStack {
                    Icon(type!.image).cornerRadius(4)
                    VStack(alignment: .leading) {
                        Text(type!.typeName!)
                        Text("\(UnitFormatter.localizedString(from: asset.underlyingAsset.quantity, unit: .none, style: .long))")
                    }
                }
            }
        }
    }
    
    var body: some View {
        let assets = self.assets.sorted{($0.typeName ?? "") < ($1.typeName ?? "")}
        
        return List {
            ForEach(assets, id: \.underlyingAsset.itemID) { asset in
                Group {
                    if asset.nested.isEmpty {
                        AssetCell(asset: asset)
                    }
                    else {
                        NavigationLink(destination: AssetsList(assets: asset.nested)) {
                            AssetCell(asset: asset)
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
}

struct AssetsList_Previews: PreviewProvider {
    
    static var previews: some View {
        let asset = AssetsData.Asset(nested: [], underlyingAsset: ESI.Assets.Element(isBlueprintCopy: nil, isSingleton: false, itemID: -1, locationFlag: .hangar, locationID: 0, locationType: .solarSystem, quantity: 1, typeID: 645), assetName: "Spyder" ,typeName: "Dominix")
        return AssetsList(assets: [asset])
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
