//
//  ContractInfoInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class ContractInfoInteractor: TreeInteractor {
	typealias Presenter = ContractInfoPresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	struct Value {
		var contract: ESI.Contracts.Contract
		var bids: [ESI.Contracts.Bid]?
		var items: [ESI.Contracts.Item]?
		var locations: [Int64: EVELocation]?
		var contacts: [Int64: Contact]?
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let contract = presenter?.view?.input else {return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		let progress = Progress(totalUnitCount: 4)
		let api = self.api
		return Services.sde.performBackgroundTask { context -> Content in
			let bids = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.contractBids(contractID: Int64(contract.contractID), cachePolicy: cachePolicy)}.get()
			let items = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.contractItems(contractID: Int64(contract.contractID), cachePolicy: cachePolicy)}.get()
			
			let locationIDs = [contract.startLocationID, contract.endLocationID].compactMap {$0}
			let contactIDs = ([contract.acceptorID, contract.assigneeID, contract.issuerID] + (bids?.value.map {$0.bidderID} ?? []))
				.filter{$0 > 0}
				.map{Int64($0)}
			
			let locations = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.locations(with: Set(locationIDs))}.get()
			let contacts = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.contacts(with: Set(contactIDs))}.get()
			
			let value = Value(contract: contract,
							  bids: bids?.value,
							  items: items?.value,
							  locations: locations,
							  contacts: contacts)
			let expires = [bids?.expires, items?.expires].compactMap{$0}.min()
			return ESI.Result(value: value, expires: expires, metadata: nil)
		}
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
