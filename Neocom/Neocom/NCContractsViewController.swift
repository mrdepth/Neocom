//
//  NCContractsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import Futures

class NCContractsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		return dataManager.contracts().then(on: .main) { result -> [NCCacheRecord] in
			self.contracts = result
			return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
		}
	}
	
	override func content() -> Future<TreeNode?> {
		let contracts = self.contracts
		let dataManager = self.dataManager
		let progress = Progress(totalUnitCount: 2)

		return DispatchQueue.global(qos: .utility).async { () -> TreeNode? in
			guard let contracts = contracts?.value else {throw NCTreeViewControllerError.noResult}
			let value = Set(contracts)
			
			var locationIDs = Set(value.compactMap {$0.startLocationID})
			locationIDs.formUnion(Set(value.compactMap {$0.endLocationID}))
			
			var contactIDs = Set(value.compactMap {$0.issuerID > 0 ? Int64($0.issuerID) : nil})
			contactIDs.formUnion(Set(value.compactMap {$0.acceptorID > 0 ? Int64($0.acceptorID) : nil}))
			contactIDs.formUnion(Set(value.compactMap {$0.assigneeID > 0 ? Int64($0.assigneeID) : nil}))
			
			
			let characterID = self.characterID ?? 0

			let contacts = try? progress.perform {dataManager.contacts(ids: contactIDs)}.get()
			let locations = try? progress.perform {dataManager.locations(ids: locationIDs)}.get()
			return try NCDatabase.sharedDatabase!.performTaskAndWait { managedObjectContext in
				var open = value.filter {$0.isOpen}.map {NCContractRow(contract: $0, characterID: characterID, contacts: contacts, location: $0.startLocationID != nil ? locations?[$0.startLocationID!] : nil)}
				var closed = value.filter {!$0.isOpen}.map {NCContractRow(contract: $0, characterID: characterID, contacts: contacts, location: $0.startLocationID != nil ? locations?[$0.startLocationID!] : nil)}
				
				open.sort {$0.contract.dateExpired < $1.contract.dateExpired}
				closed.sort {$0.endDate > $1.endDate}
				
				var rows = open
				rows.append(contentsOf: closed)
				guard !rows.isEmpty else {throw NCTreeViewControllerError.noResult}
				return RootNode(rows)
			}
		}

	}
	
	private var contracts: CachedValue<[ESI.Contracts.Contract]>?
	private var characterID: Int64?
	
}
