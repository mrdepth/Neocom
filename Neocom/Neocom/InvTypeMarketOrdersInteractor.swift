//
//  InvTypeMarketOrdersInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/26/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class InvTypeMarketOrdersInteractor: TreeInteractor {
	typealias Presenter = InvTypeMarketOrdersPresenter
	typealias Content = ESI.Result<[ESI.Market.Order]>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	private var api: API = Services.api.current
	private(set) var regionID: Int = Services.settings.marketRegionID
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		let regionID = Services.settings.marketRegionID
		self.regionID = regionID
		guard let input = presenter?.view?.input else { return .init(.failure(NCError.invalidInput(type: type(of: self)))) }
		let typeID: Int
		switch input {
		case let .typeID(id):
			typeID = id
		}
		
		return api.marketOrders(typeID: typeID, regionID: regionID, cachePolicy: cachePolicy)
	}
	
	func configure() {
	}
	
	func isExpired(_ content: Content) -> Bool {
		let regionID = Services.settings.marketRegionID
		if self.regionID != regionID {
			return true
		}
		guard let expires = content.expires else {return true}
		return expires < Date()
	}
	
	func locations(ids: Set<Int64>) -> Future<[Int64: EVELocation]> {
		return api.locations(with: ids)
	}
	
}
