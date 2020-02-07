//
//  AssetsData.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import CoreData
import Combine
import Alamofire
import Expressible

class AssetsData: ObservableObject {
    @Published var locations: Result<[LocationGroup], AFError>?
    @Published var types: Result<[Int: [LocationGroup]], AFError>?
    
    struct LocationGroup {
        var location: EVELocation
        var assets: [Asset]
        var count: Int {
            return assets.map{$0.count}.reduce(0, +)
        }
    }
    
    struct Asset {
        var nested: [Asset]
        var underlyingAsset: ESI.Assets.Element
        var assetName: String?
        var typeName: String?
        var groupName: String?
        var categoryName: String?
        var count: Int {
            return nested.map{$0.count}.reduce(1, +)
        }
    }
    
    
    init(esi: ESI, characterID: Int64, managedObjectContext: NSManagedObjectContext) {
        let character = esi.characters.characterID(Int(characterID))

        let assets = character.assets().get()
            .flatMap { response in//-> AnyPublisher<ESI.Assets, AFError> in
                Publishers.Sequence(sequence: 1..<min(10, (response.httpHeaders?["x-pages"].flatMap{Int($0)} ?? 1)))
                    .dropFirst()
                    .setFailureType(to: AFError.self)
                    .flatMap { page in character.assets().get(page: page) }
                    .map{$0.value}
                    .scan(response.value, +)
//                .eraseToAnyPublisher()
        }
        
        var assetNames = Atomic<[Int64: String?]>([:])
        
        func regroup(_ assets: ESI.Assets, locations: [Int64: EVELocation], names: [Int64: String?]) -> ([LocationGroup], [Int: [LocationGroup]]) {
            if !names.isEmpty {
                assetNames.transform { assetNames in
                    assetNames.merge(names, uniquingKeysWith: {a, b in a ?? b})
                }
            }
            let allAssetNames = assetNames.wrappedValue
            
            let locationGroup = Dictionary(grouping: assets, by: {$0.locationID})
            let items = Dictionary(assets.map{($0.itemID, $0)}, uniquingKeysWith: {a, _ in a})
            let typeIDs = Set(assets.map{$0.typeID})
            let invTypes = try? managedObjectContext.from(SDEInvType.self)
                .filter((\SDEInvType.typeID).in(typeIDs))
                .fetch()
            let typesMap = Dictionary(invTypes?.map{(Int($0.typeID), $0)} ?? [], uniquingKeysWith: {a, _ in a})

            let locationIDs = Set(locationGroup.keys).subtracting(items.keys)
            
            func extract(_ assets: ESI.Assets) -> [Asset] {
                assets.map { asset -> Asset in
                    let type = typesMap[asset.typeID]
                    return Asset(nested: extract(locationGroup[asset.itemID] ?? []),
                          underlyingAsset: asset,
                          assetName: allAssetNames[asset.itemID] ?? nil,
                          typeName: type?.typeName,
                          groupName: type?.group?.groupName,
                          categoryName: type?.group?.category?.categoryName)
                }
            }
            
            let pairs = locationIDs.map { key in
                (key, extract(locationGroup[key] ?? []))
            }
            
            func getRootLocation(from asset: ESI.Assets.Element) -> Int64 {
                return items[asset.locationID].map{getRootLocation(from: $0)} ?? asset.locationID
            }
            
            var unknownLocation = LocationGroup(location: .unknown(0), assets: [])
            var byLocations = [LocationGroup]()
            for (locationID, assets) in pairs {
                if let location = locations[locationID] {
                    byLocations.append(LocationGroup(location: location, assets: assets))
                }
                else {
                    unknownLocation.assets.append(contentsOf: assets)
                }
            }
            byLocations.sort{$0.location.name < $1.location.name}
            if !unknownLocation.assets.isEmpty {
                byLocations.append(unknownLocation)
            }
            
            let types = Dictionary(grouping: assets, by: {$0.typeID})
            let byTypes = types.mapValues {
                Dictionary(grouping: $0, by: {getRootLocation(from: $0)})
            }.mapValues { i -> [LocationGroup] in
                var unknownLocation = LocationGroup(location: .unknown(0), assets: [])
                var byLocations = [LocationGroup]()
                
                for (locationID, assets) in i {
                    let assets = assets.map{Asset(nested: [], underlyingAsset: $0)}
                    if let location = locations[locationID] {
                        byLocations.append(LocationGroup(location: location, assets: assets))
                    }
                    else {
                        unknownLocation.assets.append(contentsOf: assets)
                    }
                }
                byLocations.sort{$0.location.name < $1.location.name}
                if !unknownLocation.assets.isEmpty {
                    byLocations.append(unknownLocation)
                }

                return byLocations
            }
            return (byLocations, byTypes)
        }
        
        assets.map{$0.filter{$0.locationFlag != .implant && $0.locationFlag != .skill}}
            .receive(on: managedObjectContext)
            .flatMap { assets -> AnyPublisher<([LocationGroup], [Int: [LocationGroup]]), AFError> in
                let typeIDs = assets.map{$0.typeID}
                let namedTypeIDs = typeIDs.isEmpty ? Set() : Set(
                    (try? managedObjectContext.from(SDEInvType.self)
                        .filter((\SDEInvType.typeID).in(typeIDs) && \SDEInvType.group?.category?.categoryID == SDECategoryID.ship.rawValue)
                        .select([\SDEInvType.typeID])
                        .fetch().compactMap{$0["typeID"] as? Int}) ?? [])
                
                let namedAssetIDs = Set(assets.filter {namedTypeIDs.contains($0.typeID)}.map{$0.itemID}).subtracting(assetNames.wrappedValue.keys)
                
                let names: AnyPublisher<[Int64: String?], AFError>
                if !namedAssetIDs.isEmpty {
                    names = character.assets().names().post(itemIds: Array(namedAssetIDs))
                        .map { names in
                            Dictionary(names.value.map{($0.itemID, $0.name)}, uniquingKeysWith: {a, _ in a})
                                .merging(namedAssetIDs.map{($0, nil)}, uniquingKeysWith: {a, b in a ?? b})
                    }.eraseToAnyPublisher()
                }
                else {
                    names = Just([:]).setFailureType(to: AFError.self).eraseToAnyPublisher()
                }
                return EVELocation.locations(with: Set(assets.map{$0.locationID}).subtracting(assets.map{$0.itemID}), esi: esi, managedObjectContext: managedObjectContext)
                    .setFailureType(to: AFError.self)
                    .zip(names)
                    .receive(on: managedObjectContext)
                    .map { (locations, names) in
                        regroup(assets, locations: locations, names: names)
                }.eraseToAnyPublisher()
        }
        .asResult()
        .receive(on: RunLoop.main)
        .sink { [weak self] result in
            self?.locations = result.map{$0.0}
            self?.types = result.map{$0.1}
        }.store(in: &subscriptions)
    }
    
    var subscriptions = Set<AnyCancellable>()
}
