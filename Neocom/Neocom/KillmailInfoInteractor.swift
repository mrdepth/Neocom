//
//  KillmailInfoInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/14/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData

class KillmailInfoInteractor: TreeInteractor {
	typealias Presenter = KillmailInfoPresenter
	weak var presenter: Presenter?
	
	struct Content {
		var contacts: [Int64: Contact]?
		var prices: [Int: Double]?
	}
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let input = presenter?.view?.input else {return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		let api = self.api
		let progress = Progress(totalUnitCount: 2)
		return DispatchQueue.global(qos: .utility).async { () -> Content in
			let contactIDs = ([input.victim.characterID, input.victim.corporationID, input.victim.allianceID] +
				input.attackers.flatMap {[$0.characterID, $0.corporationID, $0.allianceID]}).compactMap{$0}.map{Int64($0)}
			let items = input.victim.items?.flatMap { [$0.itemTypeID] + ($0.items?.map {$0.itemTypeID} ?? []) }
			
			let contacts = try? progress.performAsCurrent(withPendingUnitCount: 1) {api.contacts(with: Set(contactIDs))}.get()
			let prices = try? progress.performAsCurrent(withPendingUnitCount: 1) {items.map {api.prices(typeIDs: Set($0))}}?.get()
			
			return Content(contacts: contacts, prices: prices ?? nil)
		}
	}
	
	func isExpired(_ content: Content) -> Bool {
		return false
	}
}
