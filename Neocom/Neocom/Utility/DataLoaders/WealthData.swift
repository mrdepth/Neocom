//
//  WealthData.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/20/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation

import EVEAPI
import CoreData
import Combine
import Alamofire
import Expressible

class WealthData: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()
    
    private let assetsData: AssetsData
    
    @Published var prices: Result<[Int: Double], AFError>?
    @Published var industry: Result<Double, AFError>?
    @Published var marketOrders: Result<Double, AFError>?
    @Published var blueprints: Result<Double, AFError>?
    @Published var implants: Result<Double, AFError>?
    @Published var wallet: Result<Double, AFError>?
    @Published var contracts: Result<Double, AFError>?
    @Published var assets: Result<Double, AFError>?

    init(esi: ESI, characterID: Int64, managedObjectContext: NSManagedObjectContext) {
        assetsData = AssetsData(esi: esi, characterID: characterID, managedObjectContext: managedObjectContext)
        
        
        let character = esi.characters.characterID(Int(characterID))
        
        esi.markets.prices().get()
            .map {
                Dictionary($0.value.map{($0.typeID, $0.averagePrice)}) { (a, b) in a ?? b}.compactMapValues{$0}
        }
        .receive(on: RunLoop.main)
        .asResult()
        .sink { [weak self] result in
            self?.prices = result
        }.store(in: &subscriptions)
        
        let industryJobsStatuses: Set<ESI.IndustryJobStatus> = Set([.active, .paused, .ready])
        
        $prices.compactMap{$0}.tryGet().flatMap { prices -> AnyPublisher<Double, AFError>  in
            character.industry().jobs().get(includeCompleted: true)
                .map { jobs -> [(Int, Int)] in
                    jobs.value.filter{$0.productTypeID != nil && industryJobsStatuses.contains($0.status)}
                        .map{($0.productTypeID!, $0.runs)}
            }
            .map { products -> Double in
                products.compactMap { i -> Double? in
                    prices[i.0].map{$0 * Double(i.1)}
                }.reduce(0, +)
            }.eraseToAnyPublisher()
        }.receive(on: RunLoop.main)
            .asResult()
            .sink { [weak self] result in
                self?.industry = result
        }.store(in: &subscriptions)
        
        $prices.compactMap{$0}.tryGet().flatMap { prices in
            character.orders().get().map{$0.value}.map { orders -> Double in
                orders.map{ order -> Double in
                    if order.isBuyOrder == true {
                        return order.price * Double(order.volumeRemain)
                    }
                    else {
                        return (prices[order.typeID] ?? 0) * Double(order.volumeRemain)
                    }
                }.reduce(0, +)
            }
        }.receive(on: RunLoop.main)
            .asResult()
            .sink { [weak self] result in
                self?.marketOrders = result
        }.store(in: &subscriptions)
        
        
        $prices.compactMap{$0}.tryGet().flatMap { prices in
            character.blueprints().get().map{$0.value}.receive(on: managedObjectContext).map { blueprints in
                blueprints.map{blueprint -> Double in
                    guard let blueprintType = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(blueprint.typeID)).first()?.blueprintType else {return 0}
                    guard let manufacturing = (blueprintType.activities?.allObjects as? [SDEIndActivity])?.first(where: {$0.activity?.activityID == SDEIndActivityID.manufacturing.rawValue}) else {return 0}
                    
                    let materials = (manufacturing.requiredMaterials?.allObjects as? [SDEIndRequiredMaterial])?.map { material -> Double in
                        guard let typeID = material.materialType?.typeID else {return 0}
                        guard let price = prices[Int(typeID)] else {return 0}
                        let count = (Double(material.quantity) * (1.0 - Double(blueprint.materialEfficiency) / 100.0) * 1.0).rounded(.up) * Double(blueprint.runs)
                        return count * price
                    }.reduce(0, +) ?? 0
                    
                    let products = (manufacturing.products?.allObjects as? [SDEIndProduct])?.map { product -> Double in
                        guard let typeID = product.productType?.typeID else {return 0}
                        guard let price = prices[Int(typeID)] else {return 0}
                        let count = Double(product.quantity) * Double(blueprint.runs)
                        return count * price
                    }.reduce(0, +) ?? 0
                    return max(products - materials, 0)
                }.reduce(0, +)
            }
        }.receive(on: RunLoop.main)
            .asResult()
            .sink { [weak self] result in
                self?.blueprints = result
        }.store(in: &subscriptions)
        
        let implants = character.clones().get().map{$0.value.jumpClones.flatMap{$0.implants}}
            .zip(character.implants().get().map{$0.value}).map {$0 + $1}
        
        $prices.compactMap{$0}.tryGet().flatMap { prices -> AnyPublisher<Double, AFError> in
            implants.map { implants in
                implants.compactMap{prices[$0]}.reduce(0, +)
            }.eraseToAnyPublisher()
        }.receive(on: RunLoop.main)
            .asResult()
            .sink { [weak self] result in
                self?.implants = result
        }.store(in: &subscriptions)
        
        character.wallet().get().map{$0.value}
            .receive(on: RunLoop.main)
            .asResult()
            .sink { [weak self] result in
                self?.wallet = result
        }.store(in: &subscriptions)
        
        character.contracts().get().map { contracts -> Double in
            contracts.value.filter {contract in Int64(contract.issuerID) == characterID && (contract.status == .inProgress || contract.status == .outstanding)}
                .compactMap {$0.price}
                .reduce(0, +)
        }.receive(on: RunLoop.main)
            .asResult()
            .sink { [weak self] result in
                self?.contracts = result
        }.store(in: &subscriptions)
        
        
        $prices.compactMap{$0}.tryGet()
            .zip(assetsData.categoriesPublisher)
            .receive(on: DispatchQueue.global(qos: .utility))
            .map { (prices, categories) -> Double in
                categories.flatMap { category -> [AssetsData.Asset] in
                    category.types.flatMap { type -> [AssetsData.Asset] in
                        type.locations.flatMap { location -> [AssetsData.Asset] in
                            location.assets
                        }
                    }
                }.map { asset in
                    (prices[asset.underlyingAsset.typeID] ?? 0) * Double(asset.underlyingAsset.quantity)
                }.reduce(0, +)
        }.receive(on: RunLoop.main)
            .asResult()
            .sink { [weak self] result in
                self?.assets = result
        }.store(in: &subscriptions)
        
    }
}
