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
    @Published var categories: Result<[Category], AFError>?
    
    struct LocationGroup {
        var location: EVELocation
        var assets: [Asset]
        var count: Int {
            return assets.map{$0.count}.reduce(0, +)
        }
    }
    
    struct Category: Identifiable {
        struct AssetType {
            var typeID: Int32
            var typeName: String
            var locations: [LocationGroup]
            var count: Int {
                locations.map{$0.assets.count}.reduce(0, +)
            }
        }
        var categoryName: String
        var id: Int32
        var types: [AssetType]
        var count: Int {
            types.map{$0.count}.reduce(0, +)
        }
    }
    
    struct Asset: Codable {
        var nested: [Asset]
        var underlyingAsset: ESI.Assets.Element
        var assetName: String?
        var typeName: String
        var groupName: String
        var categoryName: String
        var categoryID: Int32
        var count: Int {
            return nested.map{$0.count}.reduce(1, +)
        }
    }
    
    fileprivate struct PartialResult {
        var locations: [LocationGroup] = []
        var categories: [Category] = []
    }
    
    private static func getNames(of assets: ESI.Assets, managedObjectContext: NSManagedObjectContext, character: ESI.Characters.CharacterID, cache: [Int64: String?]) -> AnyPublisher<[Int64: String?], Never> {
        return Future<Set<Int64>, Never> { promise in
            managedObjectContext.perform {
                let typeIDs = assets.map{Int32($0.typeID)}
                let namedTypeIDs = typeIDs.isEmpty ? Set() : Set(
                    (try? managedObjectContext.from(SDEInvType.self)
                        .filter(Expressions.keyPath(\SDEInvType.typeID).in(typeIDs) && Expressions.keyPath(\SDEInvType.group?.category?.categoryID) == SDECategoryID.ship.rawValue)
                        .select(Expressions.keyPath(\SDEInvType.typeID))
                        .fetch().compactMap{$0}) ?? [])
                let namedAssetIDs = Set(assets.filter {namedTypeIDs.contains(Int32($0.typeID))}.map{$0.itemID}).subtracting(cache.keys)
                promise(.success(namedAssetIDs))
            }
        }.flatMap { namedAssetIDs -> AnyPublisher<[Int64: String?], Never> in
            let names: AnyPublisher<[Int64: String?], Never>
            if !namedAssetIDs.isEmpty {
                names = character.assets().names().post(itemIds: Array(namedAssetIDs))
                    .map{$0.value}
                    .replaceError(with: [])
                    .map { names in
                        Dictionary(names.map{($0.itemID, $0.name)}, uniquingKeysWith: {a, _ in a})
                            .merging(namedAssetIDs.map{($0, nil)}, uniquingKeysWith: {a, b in a ?? b})
                }
                .eraseToAnyPublisher()
            }
            else {
                names = Just([:]).eraseToAnyPublisher()
            }
            return names.map { names -> [Int64: String?] in
                cache.merging(names, uniquingKeysWith: {a, b in a ?? b})
            }.eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
    
    private static func getLocations(of assets: ESI.Assets, managedObjectContext: NSManagedObjectContext, esi: ESI, cache: [Int64: EVELocation?]) -> AnyPublisher<[Int64: EVELocation?], Never> {
        let locationIDs = Set(assets.map{$0.locationID}).subtracting(assets.map{$0.itemID}).subtracting(cache.keys)
        
        return EVELocation.locations(with: locationIDs, esi: esi, managedObjectContext: managedObjectContext).map { result in
            result.mapValues{$0 as Optional}.merging(locationIDs.map{($0, nil)}, uniquingKeysWith: {a, b in a ?? b})
        }.map { locations -> [Int64: EVELocation?] in
            cache.merging(locations, uniquingKeysWith: {a, b in a ?? b})
        }.eraseToAnyPublisher()
    }
    
    private static func regroup(assets: ESI.Assets, names: [Int64: String?], locations: [Int64: EVELocation?], managedObjectContext: NSManagedObjectContext) -> PartialResult {
        let locationGroup = Dictionary(grouping: assets, by: {$0.locationID})
        let items = Dictionary(assets.map{($0.itemID, $0)}, uniquingKeysWith: {a, _ in a})
        let typeIDs = Set(assets.map{Int32($0.typeID)})
        let invTypes = try? managedObjectContext.from(SDEInvType.self)
            .filter(Expressions.keyPath(\SDEInvType.typeID).in(typeIDs))
            .fetch()
        let typesMap = Dictionary(invTypes?.map{(Int($0.typeID), $0)} ?? [], uniquingKeysWith: {a, _ in a})

        let locationIDs = Set(locationGroup.keys).subtracting(items.keys)
        
        var assetIDsMap = [Int64: Asset]()

        func makeAsset(underlying asset: ESI.Assets.Element) -> Asset {
            let type = typesMap[asset.typeID]
            let result = Asset(nested: extract(locationGroup[asset.itemID] ?? []).sorted{$0.typeName < $1.typeName},
                  underlyingAsset: asset,
                  assetName: names[asset.itemID] ?? nil,
                  typeName: type?.typeName ?? "",
                  groupName: type?.group?.groupName ?? "",
                  categoryName: type?.group?.category?.categoryName ?? "",
                  categoryID: type?.group?.category?.categoryID ?? 0)
            assetIDsMap[asset.itemID] = result
            return result
        }

        func extract(_ assets: ESI.Assets) -> [Asset] {
            assets.map { asset -> Asset in
                makeAsset(underlying: asset)
            }
        }

        func getRootLocation(from asset: ESI.Assets.Element) -> Int64 {
            return items[asset.locationID].map{getRootLocation(from: $0)} ?? asset.locationID
        }
        
        var unknownLocation = LocationGroup(location: .unknown(0), assets: [])
        var byLocations = [LocationGroup]()

        for locationID in locationIDs {
            let assets = extract(locationGroup[locationID] ?? [])
            if let location = locations[locationID] ?? nil {
                byLocations.append(LocationGroup(location: location, assets: assets))
            }
            else {
                unknownLocation.assets.append(contentsOf: assets)
            }
        }
        
        for i in byLocations.indices {
            byLocations[i].assets.sort{$0.typeName < $1.typeName}
        }
        byLocations.sort{$0.location.name < $1.location.name}
        if !unknownLocation.assets.isEmpty {
            byLocations.append(unknownLocation)
        }
        
        var categories = [String: [Int: Category.AssetType]]()
        
        for location in byLocations {
            var types = [Int: [Asset]]()
            func process(_ assets: [Asset]) {
                for asset in assets {
                    types[asset.underlyingAsset.typeID, default: []].append(asset)
                    process(asset.nested)
                }
            }
            process(location.assets)
            for i in types.values {
                let typeName = i[0].typeName
                let categoryName = i[0].categoryName
                let typeID = i[0].underlyingAsset.typeID
                categories[categoryName, default: [:]][typeID, default: Category.AssetType(typeID: Int32(typeID), typeName: typeName, locations: [])].locations.append(LocationGroup(location: location.location, assets: i))
            }
        }
        let byCategories = categories.sorted{$0.key < $1.key}.map { i in
            Category(categoryName: i.key,
                     id: i.value.first?.value.locations.first?.assets.first?.categoryID ?? 0,
                     types: i.value.values.sorted{$0.typeName < $1.typeName})
        }
        
        return PartialResult(locations: byLocations, categories: byCategories)
    }
    
    var progress = Progress(totalUnitCount: 3)
    

    init(esi: ESI, characterID: Int64, managedObjectContext: NSManagedObjectContext) {
        let character = esi.characters.characterID(Int(characterID))
        let progress = self.progress
        
        let initialProgress = Progress(totalUnitCount: 100, parent: progress, pendingUnitCount: 1)
        
        func getXPages<T>(from response: ESIResponse<T>) -> Range<Int> {
            guard let header = response.httpHeaders?["x-pages"], let pages = Int(header) else {return 1..<1}
            return 1..<max(pages, 1)
        }
        
        var assetNames = [Int64: String?]()
        var locations = [Int64: EVELocation?]()

        func process(assets: ESI.Assets) -> AnyPublisher<PartialResult, Never> {
            let a = AssetsData.getNames(of: assets, managedObjectContext: managedObjectContext, character: character, cache: assetNames).map { i -> [Int64: String?] in
                assetNames = i
                return i
            }
            
            let b = AssetsData.getLocations(of: assets, managedObjectContext: managedObjectContext, esi: esi, cache: locations).map { i -> [Int64: EVELocation?] in
                locations = i
                return i
            }
            
            return Publishers.Zip(a, b)
                .receive(on: managedObjectContext)
                .map { (names, locations) in
                    AssetsData.regroup(assets: assets, names: names, locations: locations, managedObjectContext: managedObjectContext)
            }.eraseToAnyPublisher()
        }
        
        func download(_ pages: Range<Int>) -> AnyPublisher<ESI.Assets, AFError> {
            progress.performAsCurrent(withPendingUnitCount: 2, totalUnitCount: Int64(pages.count)) { p in
                pages.publisher.setFailureType(to: AFError.self)
                    .flatMap { page in
                        p.performAsCurrent(withPendingUnitCount: 1, totalUnitCount: 100) { p in
                            character.assets().get(page: page) { p.completedUnitCount = Int64($0.fractionCompleted * 100) }
                                .map{$0.value}
                        }
                        
                }
                .eraseToAnyPublisher()
            }
        }
        
        character.assets().get { initialProgress.completedUnitCount = Int64($0.fractionCompleted * 100) }
            .flatMap { result in
                Just(result.value).setFailureType(to: AFError.self)
                    .merge(with: download(getXPages(from: result).dropFirst()))
        }.reduce([], +).flatMap {
            process(assets: $0).setFailureType(to: AFError.self)
        }.asResult()
        .receive(on: RunLoop.main)
        .sink { [weak self] result in
            self?.locations = result.map{$0.locations}
            self?.categories = result.map{$0.categories}
        }.store(in: &subscriptions)

        //.scan(PartialResult(), +)
        
//            .map {response in (pages: getXPages(from: response).dropFirst(), response: response.value)}
//            .flatMap { (pages, response) in
//                progress.performAsCurrent(withPendingUnitCount: 1) {
//
//                }
//        }

        /*let first = Progress(totalUnitCount: 100, parent: progress, pendingUnitCount: 1)
        
        let assets = character.assets().get { p in
            first.completedUnitCount += min(Int64(p.fractionCompleted * 100), 100)
        }
        .map {response in ((1..<max((response.httpHeaders?["x-pages"].flatMap{Int($0)} ?? 1), 1)).dropFirst(),
                           response.value)}
        .flatMap { (pages: Range<Int>, value: ESI.Assets) in
            progress.performAsCurrent(withPendingUnitCount: 2) { () -> AnyPublisher<ESI.Assets, AFError> in
                let p = Progress(totalUnitCount: Int64(pages.count))
                return Publishers.Sequence(sequence: pages.map{ ($0, Progress(totalUnitCount: 100, parent: p, pendingUnitCount: 1)) })
                    .setFailureType(to: AFError.self)
                    .flatMap { (page, progress) in
                        character.assets().get(page: page) { p in
                            progress.completedUnitCount += min(Int64(p.fractionCompleted * 100), 100)
                        }
                    }
                    .map{$0.value}
//                    .replaceError(with: [])
//                    .setFailureType(to: AFError.self)
                    .scan(value, +)
                    .eraseToAnyPublisher()
            }
        }
        
        var assetNames = [Int64: String?]()
        var locations = [Int64: EVELocation?]()
        
        func regroup(_ assets: ESI.Assets, newLocations: [Int64: EVELocation?], names: [Int64: String?]) -> ([LocationGroup], [Category]) {
            if !names.isEmpty {
                assetNames.merge(names, uniquingKeysWith: {a, b in a ?? b})
            }

            if !newLocations.isEmpty {
                locations.merge(newLocations, uniquingKeysWith: {a, b in a ?? b})
            }

            let locationGroup = Dictionary(grouping: assets, by: {$0.locationID})
            let items = Dictionary(assets.map{($0.itemID, $0)}, uniquingKeysWith: {a, _ in a})
            let typeIDs = Set(assets.map{$0.typeID})
            let invTypes = try? managedObjectContext.from(SDEInvType.self)
                .filter((\SDEInvType.typeID).in(typeIDs))
                .fetch()
            let typesMap = Dictionary(invTypes?.map{(Int($0.typeID), $0)} ?? [], uniquingKeysWith: {a, _ in a})

            let locationIDs = Set(locationGroup.keys).subtracting(items.keys)
            
            
            var assetIDsMap = [Int64: Asset]()

            func makeAsset(underlying asset: ESI.Assets.Element) -> Asset {
                let type = typesMap[asset.typeID]
                let result = Asset(nested: extract(locationGroup[asset.itemID] ?? []).sorted{$0.typeName < $1.typeName},
                      underlyingAsset: asset,
                      assetName: assetNames[asset.itemID] ?? nil,
                      typeName: type?.typeName ?? "",
                      groupName: type?.group?.groupName ?? "",
                      categoryName: type?.group?.category?.categoryName ?? "",
                      categoryID: Int(type?.group?.category?.categoryID ?? 0))
                assetIDsMap[asset.itemID] = result
                return result
            }

            func extract(_ assets: ESI.Assets) -> [Asset] {
                assets.map { asset -> Asset in
                    makeAsset(underlying: asset)
                }
            }

            func getRootLocation(from asset: ESI.Assets.Element) -> Int64 {
                return items[asset.locationID].map{getRootLocation(from: $0)} ?? asset.locationID
            }
            
            var unknownLocation = LocationGroup(location: .unknown(0), assets: [])
            var byLocations = [LocationGroup]()

            for locationID in locationIDs {
                let assets = extract(locationGroup[locationID] ?? [])
                if let location = locations[locationID] ?? nil {
                    byLocations.append(LocationGroup(location: location, assets: assets))
                }
                else {
                    unknownLocation.assets.append(contentsOf: assets)
                }
            }
            
            for i in byLocations.indices {
                byLocations[i].assets.sort{$0.typeName < $1.typeName}
            }
            byLocations.sort{$0.location.name < $1.location.name}
            if !unknownLocation.assets.isEmpty {
                byLocations.append(unknownLocation)
            }
            
            var categories = [String: [Int: Category.AssetType]]()
            
            for location in byLocations {
                var types = [Int: [Asset]]()
                func process(_ assets: [Asset]) {
                    for asset in assets {
                        types[asset.underlyingAsset.typeID, default: []].append(asset)
                        process(asset.nested)
                    }
                }
                process(location.assets)
                for i in types.values {
                    let typeName = i[0].typeName
                    let categoryName = i[0].categoryName
                    let typeID = i[0].underlyingAsset.typeID
                    categories[categoryName, default: [:]][typeID, default: Category.AssetType(typeID: typeID, typeName: typeName, locations: [])].locations.append(LocationGroup(location: location.location, assets: i))
                }
            }
            let byCategories = categories.sorted{$0.key < $1.key}.map { i in
                Category(categoryName: i.key,
                         id: i.value.first?.value.locations.first?.assets.first?.categoryID ?? 0,
                         types: i.value.values.sorted{$0.typeName < $1.typeName})
            }
            
            return (byLocations, byCategories)
        }
        
        assets.map{$0.filter{$0.locationFlag != .implant && $0.locationFlag != .skill}}
            .receive(on: managedObjectContext)
            .flatMap { assets -> AnyPublisher<([LocationGroup], [Category]), AFError> in
                let typeIDs = assets.map{$0.typeID}
                let namedTypeIDs = typeIDs.isEmpty ? Set() : Set(
                    (try? managedObjectContext.from(SDEInvType.self)
                        .filter((\SDEInvType.typeID).in(typeIDs) && \SDEInvType.group?.category?.categoryID == SDECategoryID.ship.rawValue)
                        .select([\SDEInvType.typeID])
                        .fetch().compactMap{$0["typeID"] as? Int}) ?? [])
                
                let namedAssetIDs = Set(assets.filter {namedTypeIDs.contains($0.typeID)}.map{$0.itemID}).subtracting(assetNames.keys)
                let locationIDs = Set(assets.map{$0.locationID}).subtracting(assets.map{$0.itemID}).subtracting(locations.keys)
                
                let names: AnyPublisher<[Int64: String?], Never>
                if !namedAssetIDs.isEmpty {
                    names = character.assets().names().post(itemIds: Array(namedAssetIDs))
                        .map{$0.value}
                        .replaceError(with: [])
                        .map { names in
                            Dictionary(names.map{($0.itemID, $0.name)}, uniquingKeysWith: {a, _ in a})
                                .merging(namedAssetIDs.map{($0, nil)}, uniquingKeysWith: {a, b in a ?? b})
                    }
                    .eraseToAnyPublisher()
                }
                else {
                    names = Just([:]).eraseToAnyPublisher()
                }
                return EVELocation.locations(with: locationIDs, esi: esi, managedObjectContext: managedObjectContext)
                    .map{ result in
                        result.mapValues{$0 as Optional}.merging(locationIDs.map{($0, nil)}, uniquingKeysWith: {a, b in a ?? b})
                    }
                    .zip(names)
                    .receive(on: managedObjectContext)
                    .map { (locations, names) in
                        regroup(assets, newLocations: locations, names: names)
                }
                .setFailureType(to: AFError.self)
                .eraseToAnyPublisher()
        }
        .asResult()
        .receive(on: RunLoop.main)
        .sink { [weak self] result in
            self?.locations = result.map{$0.0}
            self?.categories = result.map{$0.1}
        }.store(in: &subscriptions)*/
    }
    
    var subscriptions = Set<AnyCancellable>()
}
