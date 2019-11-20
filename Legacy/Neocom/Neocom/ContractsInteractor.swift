//
//  ContractsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class ContractsInteractor: TreeInteractor {
	typealias Presenter = ContractsPresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	struct Value {
		var contracts: [ESI.Contracts.Contract]
		var locations: [Int64: EVELocation]?
		var contacts: [Int64: Contact]?
	}
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		let progress = Progress(totalUnitCount: 3)
		let api = self.api

		return DispatchQueue.global(qos: .utility).async { () -> Content in
			let contracts = try progress.performAsCurrent(withPendingUnitCount: 1) {api.contracts(cachePolicy: cachePolicy)}.get()
			
			let locationIDs = Set(contracts.value.compactMap{$0.startLocationID})
			let contactIDs = Set((contracts.value.map{Int64($0.issuerID)}).filter {$0 > 0})
			
			let locations = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.locations(with: locationIDs)}.get()
			let contacts = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.contacts(with: contactIDs)}.get()
			
			return contracts.map {Value(contracts: $0, locations: locations, contacts: contacts)}
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
