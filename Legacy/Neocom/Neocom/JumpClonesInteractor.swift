//
//  JumpClonesInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/1/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class JumpClonesInteractor: TreeInteractor {
	typealias Presenter = JumpClonesPresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	struct Value {
		var clones: ESI.Clones.JumpClones
		var locations: [Int64: EVELocation]?
	}
	
	private var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		let api = self.api
		return DispatchQueue.global(qos: .utility).async { () -> Content in
			let clones = try api.clones(cachePolicy: cachePolicy).get()
			let locationIDs = clones.value.jumpClones.compactMap {$0.locationID}
			let locations = try? api.locations(with: Set(locationIDs)).get()
			
			return clones.map { Value(clones: $0, locations: locations) }
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
