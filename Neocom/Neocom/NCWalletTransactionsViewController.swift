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
		needsReloadOnAccountChange = true
		tableView.register([Prototype.NCHeaderTableViewCell.default])
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		dataManager.walletTransactions { result in
			self.walletTransactions = result
			if let cacheRecord = result.cacheRecord {
				completionHandler([cacheRecord])
			}
			else {
				completionHandler([])
			}
		}
	}

	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = walletTransactions?.value {
			tableView.backgroundView = nil
			
			let locationIDs = Set(value.transactions.map {Int64($0.stationID)})
			
			dataManager.locations(ids: locationIDs) { locations in
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
						
						if self.treeController?.content == nil {
							self.treeController?.content = RootNode(rows)
						}
						else {
							self.treeController?.content?.children = rows
						}
						
						self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
						completionHandler()
					}
				}
			}
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: walletTransactions?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private var walletTransactions: NCCachedResult<EVE.Char.WalletTransactions>?
	
}
