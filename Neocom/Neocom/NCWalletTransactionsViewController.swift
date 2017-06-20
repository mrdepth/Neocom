//
//  NCWalletTransactionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCWalletTransactionsViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCHeaderTableViewCell.default])

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
	private var walletTransactions: NCCachedResult<EVE.Char.WalletTransactions>?
	private var locations: [Int64: NCLocation]?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		title = account.characterName
		
		let progress = Progress(totalUnitCount: 1)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		
		progress.perform {
			dataManager.walletTransactions { result in
				self.walletTransactions = result
				
				switch result {
				case let .success(_, record):
					if let record = record {
						self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
							self?.reloadLocations(dataManager: dataManager) {
								self?.reloadSections()
							}
						}
					}
					
					self.reloadLocations(dataManager: dataManager) {
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
		guard let value = walletTransactions?.value else {
			completionHandler?()
			return
		}
		let locationIDs = Set(value.transactions.map {Int64($0.stationID)})
		
		guard !locationIDs.isEmpty else {
			completionHandler?()
			return
		}
		
		dataManager.locations(ids: locationIDs) { [weak self] result in
			self?.locations = result
			completionHandler?()
		}
	}
	
	private func reloadSections() {
		if let value = walletTransactions?.value {
			tableView.backgroundView = nil
			let locations = self.locations ?? [:]
			
			NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
				
				let dateFormatter = DateFormatter()
				dateFormatter.dateStyle = .medium
				dateFormatter.timeStyle = .none
				dateFormatter.doesRelativeDateFormatting = true
				
				let transactions = value.transactions.sorted {$0.transactionDateTime > $1.transactionDateTime}
				let calendar = Calendar(identifier: .gregorian)
				
				var date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: Date())) ?? Date()
				
				var sections = [TreeNode]()
				
				var rows = [NCWalletTransactionRow]()
				for transaction in transactions {
					let row = NCWalletTransactionRow(transaction: transaction, location: locations[Int64(transaction.stationID)])
					if transaction.transactionDateTime > date {
						rows.append(row)
					}
					else {
						if !rows.isEmpty {
							let title = dateFormatter.string(from: date)
							sections.append(DefaultTreeSection(nodeIdentifier: title, title: title.uppercased(), children: rows))
						}
						date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: transaction.transactionDateTime)) ?? Date()
						rows = [row]
					}
				}
				
				if !rows.isEmpty {
					let title = dateFormatter.string(from: date)
					sections.append(DefaultTreeSection(nodeIdentifier: title, title: title.uppercased(), children: rows))
				}

				
				DispatchQueue.main.async {
					
					if self.treeController.content == nil {
						let root = TreeNode()
						root.children = sections
						self.treeController.content = root
					}
					else {
						self.treeController.content?.children = sections
					}
					self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
				}
			}
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: walletTransactions?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
	
}
