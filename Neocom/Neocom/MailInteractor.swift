//
//  MailInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/2/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class MailInteractor: ContentProviderInteractor {
	typealias Presenter = MailPresenter
	typealias Content = ESI.Result<ESI.Mail.MailLabelsAndUnreadCounts>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	private var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		return api.mailLabels(cachePolicy: cachePolicy)
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
