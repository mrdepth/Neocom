//
//  NCWalletTransactionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCWalletTransactionsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		tableView.register([Prototype.NCHeaderTableViewCell.default])
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		dataManager.walletTransactions { result in
			self.walletTransactions = result
			completionHandler([result.cacheRecord].flatMap {$0})
		}
	}

	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = walletTransactions?.value {
			tableView.backgroundView = nil
			let progress = Progress(totalUnitCount: 3)

			let locationIDs = Set(value.map {$0.locationID})
			let contactIDs = Set(value.map{Int64($0.clientID)})
			
			var locations: [Int64: NCLocation]?
			var contacts: [Int64: NCContact]?
			let dispatchGroup = DispatchGroup()
			
			progress.perform {
				if !contactIDs.isEmpty {
					dispatchGroup.enter()
					dataManager.contacts(ids: contactIDs) { result in
						contacts = result
						dispatchGroup.leave()
					}
				}
			}
			
			progress.perform {
				if !locationIDs.isEmpty {
					dispatchGroup.enter()
					dataManager.locations(ids: locationIDs) { result in
						locations = result
						dispatchGroup.leave()
					}
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
					
					let dateFormatter = DateFormatter()
					dateFormatter.dateStyle = .medium
					dateFormatter.timeStyle = .none
					dateFormatter.doesRelativeDateFormatting = true
					
					let transactions = value.sorted {$0.date > $1.date}
					let calendar = Calendar(identifier: .gregorian)
					
					var date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: Date())) ?? Date()
					
					var sections = [TreeNode]()
					
					var rows = [NCWalletTransactionRow]()
					for transaction in transactions {
						let row = NCWalletTransactionRow(transaction: transaction, location: locations?[transaction.locationID], client: contacts?[Int64(transaction.clientID)])
						if transaction.date > date {
							rows.append(row)
						}
						else {
							if !rows.isEmpty {
								let title = dateFormatter.string(from: date)
								sections.append(DefaultTreeSection(nodeIdentifier: title, title: title.uppercased(), children: rows))
							}
							date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: transaction.date)) ?? Date()
							rows = [row]
						}
					}
					
					if !rows.isEmpty {
						let title = dateFormatter.string(from: date)
						sections.append(DefaultTreeSection(nodeIdentifier: title, title: title.uppercased(), children: rows))
					}
					
					
					DispatchQueue.main.async {
						progress.completedUnitCount += 1
						
						if self.treeController?.content == nil {
							self.treeController?.content = RootNode(sections)
						}
						else {
							self.treeController?.content?.children = sections
						}
						
						self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
						completionHandler()
					}
				}
			}
			
		}
		else {
			tableView.backgroundView = treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: walletTransactions?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private var walletTransactions: NCCachedResult<[ESI.Wallet.Transaction]>?
	
}
