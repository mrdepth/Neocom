//
//  CertCertificateMasteryInfoInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/28/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class CertCertificateMasteryInfoInteractor: TreeInteractor {
	typealias Presenter = CertCertificateMasteryInfoPresenter
	typealias Content = ESI.Result<Character?>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	private var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		let promise = Promise<ESI.Result<Character?>>()
		
		api.character(cachePolicy: cachePolicy).then { result in
			try! promise.fulfill(result.map {$0 as Character?})
			}.catch { _ in
				try! promise.fulfill(ESI.Result(value: nil, expires: nil, metadata: nil))
		}
		return promise.future
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
