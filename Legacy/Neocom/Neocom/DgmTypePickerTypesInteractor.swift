//
//  DgmTypePickerTypesInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 24/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData

class DgmTypePickerTypesInteractor: TreeInteractor {
	typealias Presenter = DgmTypePickerTypesPresenter
	typealias Content = Void
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		return .init(())
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			_ = self?.presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter?.view?.present(presentation, animated: true)
			}
		}
	}
	
	func touch(_ type: SDEInvType) {
		guard let input = presenter?.view?.input else {return}

		switch input {
		case let .category(category):
			Services.cache.viewContext.typePickerRecent(category: category, type: type).date = Date()
		case let .group(group):
			guard let category = group.category else {return}
			Services.cache.viewContext.typePickerRecent(category: category, type: type).date = Date()
		}
		try? Services.cache.viewContext.save()
	}
}
