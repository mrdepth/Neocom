//
//  AssetsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI
import Expressible

class AssetsInteractor: TreeInteractor {
	typealias Presenter = AssetsPresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	struct Value {
		var assets: [ESI.Assets.Asset]
		var locations: [Int64: EVELocation]?
		var names: [Int64: ESI.Assets.Name]?
	}
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		let api = self.api
		let progress = Progress(totalUnitCount: 3)
		
		return Services.sde.performBackgroundTask { context -> Content in
			let assets = try progress.performAsCurrent(withPendingUnitCount: 1) {api.assets(cachePolicy: cachePolicy)}.get()
			
			let typeIDs = assets.value.map{$0.typeID}
			let namedTypeIDs = try Set(
				context.managedObjectContext
				.from(SDEInvType.self)
				.filter((\SDEInvType.typeID).in(typeIDs) && \SDEInvType.group?.category?.categoryID == SDECategoryID.ship.rawValue)
				.select([\SDEInvType.typeID])
				.fetch().compactMap{$0["typeID"] as? Int}
			)
			
			let namedAssetIDs = Set(assets.value.filter {namedTypeIDs.contains($0.typeID)}.map{$0.itemID})
			let itemsIDs = Set(assets.value.map {$0.itemID})
			let locationIDs = Set(assets.value.map {$0.locationID}).subtracting(itemsIDs)
			let locations = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.locations(with: locationIDs)}.get()
			let names = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.assetNames(with: namedAssetIDs, cachePolicy: cachePolicy)}.get()
			return assets.map {Value(assets: $0, locations: locations, names: names?.value)}
		}
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			self?.api = Services.api.current
			_ = self?.presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter?.view?.present(presentation, animated: true)
			}
		}
	}
}
