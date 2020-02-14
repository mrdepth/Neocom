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
    var assets: [AssetsData.Asset]
    var title: String
    var ship: AssetsData.Asset?
    
    init(_ location: AssetsData.LocationGroup) {
        assets = location.assets
        title = location.location.solarSystem?.solarSystemName ?? location.location.name
    }

    init(_ asset: AssetsData.Asset) {
        assets = asset.nested
        title = asset.assetName ?? asset.typeName
        if asset.categoryID == SDECategoryID.ship.rawValue {
            ship = asset
        }
    }

    var body: some View {
        List {
            if ship != nil {
                AssetsShipContent(ship: ship!)
            }
            else {
                AssetsListContent(assets: assets)
            }
        }.listStyle(GroupedListStyle()).navigationBarTitle(title)
    }
}

struct AssetsListContent: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var assets: [AssetsData.Asset]
    
    var body: some View {
        return ForEach(assets, id: \.underlyingAsset.itemID) { asset in
            Group {
                AssetCell(asset: asset)
            }
        }
    }
}

struct AssetsShipContent: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var ship: AssetsData.Asset
    
    var body: some View {
        let map = Dictionary(grouping: ship.nested, by: {ItemFlag(flag: $0.underlyingAsset.locationFlag) ?? .cargo})
        let assets = map.sorted {$0.key.rawValue < $1.key.rawValue}
        return ForEach(assets, id: \.key) { i in
            Section(header: i.key.tableSectionHeader) {
                ForEach(i.value, id: \.underlyingAsset.itemID) { asset in
                    AssetCell(asset: asset)
                }
            }
        }
    }
}

struct AssetsList_Previews: PreviewProvider {
    
    static var previews: some View {
        let data = NSDataAsset(name: "dominixAsset")!.data
        let asset = try! JSONDecoder().decode(AssetsData.Asset.self, from: data)
        return AssetsList(asset)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
