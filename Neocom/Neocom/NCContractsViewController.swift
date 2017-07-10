//
//  NCContractsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCContractsViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		registerRefreshable()
		
		treeController.delegate = self
		
		reload()
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.route?.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
	//MARK: - NCRefreshable
	
	private var observer: NCManagedObjectObserver?
	private var contracts: NCCachedResult<[ESI.Contracts.Contract]>?
	private var locations: [Int64: NCLocation]?
	private var contacts: [Int64: NCContact]?
	private var characterID: Int64?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		
		let progress = Progress(totalUnitCount: 1)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		
		characterID = account.characterID
		
		progress.perform {
			dataManager.contracts { result in
				self.contracts = result
				
				switch result {
				case let .success(_, record):
					if let record = record {
						self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
							guard let strongSelf = self else {return}
							
							let dispatchGroup = DispatchGroup()
							
							dispatchGroup.enter()
							strongSelf.reloadLocations(dataManager: dataManager) {
								dispatchGroup.leave()
							}
							
							dispatchGroup.enter()
							strongSelf.reloadContacts(dataManager: dataManager) {
								dispatchGroup.leave()
							}
							
							dispatchGroup.notify(queue: .main) {
								self?.reloadSections()
							}
						}
					}
					
					let dispatchGroup = DispatchGroup()
					
					dispatchGroup.enter()
					self.reloadLocations(dataManager: dataManager) {
						dispatchGroup.leave()
					}
					
					dispatchGroup.enter()
					self.reloadContacts(dataManager: dataManager) {
						dispatchGroup.leave()
					}
					
					dispatchGroup.notify(queue: .main) {
						self.reloadSections()
						completionHandler?()
					}
				case .failure:
					self.reloadSections()
					completionHandler?()
				}
				
				
			}
		}
	}
	
	private func reloadLocations(dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		guard let value = contracts?.value else {
			completionHandler?()
			return
		}
		var locationIDs = Set(value.flatMap {$0.startLocationID})
		locationIDs.formUnion(Set(value.flatMap {$0.endLocationID}))
		
		guard !locationIDs.isEmpty else {
			completionHandler?()
			return
		}
		
		dataManager.locations(ids: locationIDs) { [weak self] result in
			self?.locations = result
			completionHandler?()
		}
	}
	
	private func reloadContacts(dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		guard let value = contracts?.value else {
			completionHandler?()
			return
		}
		var contactIDs = Set(value.flatMap {$0.issuerID > 0 ? Int64($0.issuerID) : nil})
		contactIDs.formUnion(Set(value.flatMap {$0.acceptorID > 0 ? Int64($0.acceptorID) : nil}))
		contactIDs.formUnion(Set(value.flatMap {$0.assigneeID > 0 ?Int64($0.assigneeID) : nil}))
		
		guard !contactIDs.isEmpty else {
			completionHandler?()
			return
		}
		
		dataManager.contacts(ids: contactIDs) { [weak self] result in
			self?.contacts = result
			completionHandler?()
		}
	}
	
	private func reloadSections() {
		if let value = contracts?.value {
			tableView.backgroundView = nil
			let locations = self.locations ?? [:]
			let contacts = self.contacts
			let characterID = self.characterID ?? 0
			
			NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
				var open = value.filter {$0.isOpen}.map {NCContractRow(contract: $0, characterID: characterID, contacts: contacts, location: $0.startLocationID != nil ? locations[$0.startLocationID!] : nil)}
				var closed = value.filter {!$0.isOpen}.map {NCContractRow(contract: $0, characterID: characterID, contacts: contacts, location: $0.startLocationID != nil ? locations[$0.startLocationID!] : nil)}
				
				open.sort {$0.contract.dateExpired < $1.contract.dateExpired}
				closed.sort {$0.endDate > $1.endDate}
				
				var rows = open
				rows.append(contentsOf: closed)
				
				DispatchQueue.main.async {
					
					if self.treeController.content == nil {
						let root = TreeNode()
						root.children = rows
						self.treeController.content = root
					}
					else {
						self.treeController.content?.children = rows
					}
					self.tableView.backgroundView = rows.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
				}
			}
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: contracts?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
	
}
