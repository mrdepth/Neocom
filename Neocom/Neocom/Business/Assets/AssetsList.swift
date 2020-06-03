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
import Combine
import Dgmpp

struct AssetsList: View {
    var assets: [AssetsData.Asset]
    var title: String
    var ship: AssetsData.Asset?
    
    @State private var selectedProject: FittingProject?
    @State private var projectLoading: AnyPublisher<Result<FittingProject, Error>, Never>?
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState
    
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

    private var fittingButton: some View {
        Button(NSLocalizedString("Fitting", comment: "")) {
            self.projectLoading = DGMSkillLevels.load(self.sharedState.account, managedObjectContext: self.managedObjectContext)
                .receive(on: RunLoop.main)
                .tryMap { try FittingProject(asset: self.ship!, skillLevels: $0, managedObjectContext: self.managedObjectContext) }
                .asResult()
                .eraseToAnyPublisher()
        }
    }

    var body: some View {
        Group {
            if ship != nil {
                List {
                    AssetsShipContent(ship: ship!)
                }.listStyle(GroupedListStyle())
                    .overlay(self.projectLoading != nil ? ActivityIndicator() : nil)
                    .overlay(selectedProject.map{NavigationLink(destination: FittingEditor(project: $0), tag: $0, selection: $selectedProject, label: {EmptyView()})})
                    .onReceive(projectLoading ?? Empty().eraseToAnyPublisher()) { result in
                        self.projectLoading = nil
                        self.selectedProject = result.value
                }
                .navigationBarItems(trailing: fittingButton)
                
            }
            else {
                List {
                    AssetsListContent(assets: assets)
                }.listStyle(GroupedListStyle())
            }
        }
        .navigationBarTitle(title)
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

#if DEBUG
struct AssetsList_Previews: PreviewProvider {
    
    static var previews: some View {
        let data = NSDataAsset(name: "dominixAsset")!.data
        let asset = try! JSONDecoder().decode(AssetsData.Asset.self, from: data)
        return AssetsList(asset)
            .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
            .environmentObject(SharedState.testState())
    }
}
#endif
