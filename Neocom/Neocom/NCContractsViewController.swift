//
//  NCContractsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCContractsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		dataManager.contracts { result in
			self.contracts = result
			completionHandler([result.cacheRecord].flatMap {$0})
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let contracts = contracts?.value {
			let value = Set(contracts)
			tableView.backgroundView = nil
			
			var locationIDs = Set(value.flatMap {$0.startLocationID})
			locationIDs.formUnion(Set(value.flatMap {$0.endLocationID}))
			
			var contactIDs = Set(value.flatMap {$0.issuerID > 0 ? Int64($0.issuerID) : nil})
			contactIDs.formUnion(Set(value.flatMap {$0.acceptorID > 0 ? Int64($0.acceptorID) : nil}))
			contactIDs.formUnion(Set(value.flatMap {$0.assigneeID > 0 ?Int64($0.assigneeID) : nil}))

			let dispatchGroup = DispatchGroup()
			
			let progress = Progress(totalUnitCount: 2)
			
			var locations: [Int64: NCLocation] = [:]
			var contacts: [Int64: NCContact] = [:]
			let characterID = self.characterID ?? 0

			
			progress.perform {
				dispatchGroup.enter()
				dataManager.contacts(ids: contactIDs) { result in
					contacts = result
					dispatchGroup.leave()
				}
			}
			
			progress.perform {
				dispatchGroup.enter()
				dataManager.locations(ids: locationIDs) { result in
					locations = result
					dispatchGroup.leave()
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
					var open = value.filter {$0.isOpen}.map {NCContractRow(contract: $0, characterID: characterID, contacts: contacts, location: $0.startLocationID != nil ? locations[$0.startLocationID!] : nil)}
					var closed = value.filter {!$0.isOpen}.map {NCContractRow(contract: $0, characterID: characterID, contacts: contacts, location: $0.startLocationID != nil ? locations[$0.startLocationID!] : nil)}
					
					open.sort {$0.contract.dateExpired < $1.contract.dateExpired}
					closed.sort {$0.endDate > $1.endDate}
					
					var rows = open
					rows.append(contentsOf: closed)
					
					DispatchQueue.main.async {
						
						if self.treeController?.content == nil {
							self.treeController?.content = RootNode(rows)
						}
						else {
							self.treeController?.content?.children = rows
						}
						
						self.tableView.backgroundView = rows.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
						completionHandler()
					}
				}
			}
			
		}
		else {
			tableView.backgroundView = treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: contracts?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private var contracts: NCCachedResult<[ESI.Contracts.Contract]>?
	private var characterID: Int64?
	
}
