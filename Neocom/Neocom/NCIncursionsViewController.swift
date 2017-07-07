//
//  NCIncursionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCIncursionsViewController: NCTreeViewController, NCRefreshable {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		
		registerRefreshable()
		
		reload()
	}
	
	//MARK: - NCRefreshable
	
	private var observer: NCManagedObjectObserver?
	private var incursions: NCCachedResult<[ESI.Incursions.Incursion]>?
	private var contacts: [Int64: NCContact]?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		
		let progress = Progress(totalUnitCount: 1)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		
		progress.perform {
			dataManager.incursions { result in
				self.incursions = result
				
				switch result {
				case let .success(_, record):
					if let record = record {
						self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
							self?.reloadContacts(dataManager: dataManager) {
								self?.reloadSections()
							}
						}
					}
					
					self.reloadContacts(dataManager: dataManager) {
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
	
	private func reloadContacts(dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		guard let value = incursions?.value else {
			completionHandler?()
			return
		}
		let contactIDs = Set(value.map{Int64($0.factionID)})
		
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
		if let value = incursions?.value {
			let contacts = self.contacts
			
			let rows = value.map {NCIncursionRow(incursion: $0, contact: contacts?[Int64($0.factionID)])}
			
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
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: incursions?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
	
}
