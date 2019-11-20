//
//  WalletJournalPageInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class WalletJournalPageInteractor: TreeInteractor {
	typealias Presenter = WalletJournalPagePresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	struct Value {
		var walletJournal: [ESI.Wallet.WalletJournalItem]
		var balance: Double?
	}
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		let progress = Progress(totalUnitCount: 2)
		
		let api = self.api
		return DispatchQueue.global(qos: .utility).async { () -> Content in
			let journal = try progress.performAsCurrent(withPendingUnitCount: 1) {api.walletJournal(cachePolicy: cachePolicy)}.get()
			let balance = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.walletBalance(cachePolicy: cachePolicy)}.get()
			
			return journal.map {Value(walletJournal: $0, balance: balance?.value)}
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
