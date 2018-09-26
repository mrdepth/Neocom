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
	private var regionID: Int = (UserDefaults.standard.value(forKey: UserDefaults.Key.marketRegion) as? Int) ?? SDERegionID.theForge.rawValue
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let input = presenter?.view?.input else { return .init(.failure(NCError.invalidInput(type: type(of: self)))) }
		let typeID: Int
		switch input {
		case let .type(type):
			typeID = Int(type.typeID)
		}
		
		return api.marketOrders(typeID: typeID, regionID: regionID, cachePolicy: cachePolicy)
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			_ = self?.presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter?.view?.present(presentation, animated: true)
			}
		}
	}
	
	func isExpired(_ content: Content) -> Bool {
		let regionID = (UserDefaults.standard.value(forKey: UserDefaults.Key.marketRegion) as? Int) ?? SDERegionID.theForge.rawValue
		if self.regionID != regionID {
			self.regionID = regionID
			return true
		}
		guard let expires = content.expires else {return true}
		return expires < Date()
	}

}
