//
//  ZKillmailsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class ZKillmailsInteractor: TreeInteractor {
	typealias Presenter = ZKillmailsPresenter
	typealias Content = ESI.Result<[EVEAPI.ZKillboard.Killmail]>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		return load(page: nil, cachePolicy: cachePolicy)
	}
	
	func load(page: Int?, cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let input = presenter?.view?.input else {return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		return api.zKillmails(filter: input, page: page, cachePolicy: cachePolicy)
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			_ = self?.presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter?.view?.present(presentation, animated: true)
			}
		}
	}
}
