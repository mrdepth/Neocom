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
	weak var presenter: Presenter!
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		let promise = Promise<ESI.Result<Character?>>()
		Services.api.current.character(cachePolicy: .useProtocolCachePolicy).then { result in
			try! promise.fulfill(result.map {$0 as Character?})
		}.catch { _ in
			try! promise.fulfill(ESI.Result(value: nil, expires: nil))
		}
		return promise.future
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			_ = self?.presenter.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter.view.present(presentation, animated: true)
			}
		}
	}
}
