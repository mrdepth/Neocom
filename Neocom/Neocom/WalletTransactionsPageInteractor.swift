//
//  WalletTransactionsPageInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class WalletTransactionsPageInteractor: TreeInteractor {
	typealias Presenter = WalletTransactionsPagePresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	struct Value {
		var transactions: [ESI.Wallet.Transaction]
		var balance: Double?
		var contacts: [Int64: Contact]?
		var locations: [Int64: EVELocation]?
	}

	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		let progress = Progress(totalUnitCount: 4)
		
		let api = self.api
		return DispatchQueue.global(qos: .utility).async { () -> Content in
			let transactions = try progress.performAsCurrent(withPendingUnitCount: 1) {api.walletTransactions(cachePolicy: cachePolicy)}.get()
			let balance = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.walletBalance(cachePolicy: cachePolicy)}.get()
			
			let contactIDs = Set(transactions.value.map {Int64($0.clientID)}.filter{$0 > 0})
			let locationIDs = Set(transactions.value.map{$0.locationID})
			
			let contacts = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.contacts(with: contactIDs)}.get()
			let locations = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.locations(with: locationIDs)}.get()
			
			return transactions.map {Value(transactions: $0, balance: balance?.value, contacts: contacts, locations: locations)}
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
