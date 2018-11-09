//
//  MarketOrdersInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/9/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class MarketOrdersInteractor: TreeInteractor {
	typealias Presenter = MarketOrdersPresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	struct Value {
		var orders: [ESI.Market.CharacterOrder]
		var locations: [Int64: EVELocation]?
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		let api = self.api
		let progress = Progress(totalUnitCount: 2)
		return DispatchQueue.global(qos: .utility).async { () -> Content in
			let orders = try progress.performAsCurrent(withPendingUnitCount: 1) {api.openOrders(cachePolicy: cachePolicy)}.get()
			let locationIDs = orders.value.map{$0.locationID}
			let locations = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.locations(with: Set(locationIDs))}.get()
			return orders.map {Value(orders: $0, locations: locations)}
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
