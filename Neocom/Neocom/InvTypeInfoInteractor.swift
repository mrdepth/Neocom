//
//  InvTypeInfoInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class InvTypeInfoInteractor: TreeInteractor {
	typealias Presenter = InvTypeInfoPresenter
	typealias Content = ESI.Result<Character?>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	private var api: API = Services.api.current
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		let promise = Promise<ESI.Result<Character?>>()
		
		api.character(cachePolicy: .useProtocolCachePolicy).then { result in
			try! promise.fulfill(result.map {$0 as Character?})
		}.catch { _ in
			try! promise.fulfill(ESI.Result(value: nil, expires: nil, metadata: nil))
		}
		return promise.future
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	private var regionID: Int = (UserDefaults.standard.value(forKey: UserDefaults.Key.marketRegion) as? Int) ?? SDERegionID.theForge.rawValue
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			self?.api = Services.api.current
			_ = self?.presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter?.view?.present(presentation, animated: true)
			}
		}
	}
	
	func fullSizeImage(typeID: Int, dimension: Int) -> Future<UIImage> {
		return api.image(typeID: typeID, dimension: dimension, cachePolicy: .useProtocolCachePolicy).then { $0.value }
	}
	
	func price(typeID: Int) -> Future<Double> {
		return api.prices(typeIDs: Set([typeID])).then { prices in
			return prices[typeID] ?? 0
		}
	}
	
	func marketHistory(typeID: Int) -> Future<[ESI.Market.History]> {
		return api.marketHistory(typeID: typeID, regionID: regionID, cachePolicy: .useProtocolCachePolicy).then {$0.value}
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
