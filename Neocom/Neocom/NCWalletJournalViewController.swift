//
//  NCWalletJournalViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCWalletJournalViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		tableView.register([Prototype.NCHeaderTableViewCell.default])
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		dataManager.walletJournal { result in
			self.walletJournal = result
			completionHandler([self.walletJournal?.cacheRecord].flatMap {$0})
		}
		
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = walletJournal?.value {
			
			DispatchQueue.global(qos: .background).async {
				autoreleasepool {
					
					let dateFormatter = DateFormatter()
					dateFormatter.dateStyle = .medium
					dateFormatter.timeStyle = .none
					dateFormatter.doesRelativeDateFormatting = true
					
					let transactions = value.sorted {$0.date > $1.date}
					let calendar = Calendar(identifier: .gregorian)
					
					var date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: Date())) ?? Date()
					
					var sections = [TreeNode]()
					
					var rows = [NCWalletJournalRow]()
					for transaction in transactions {

						let row = NCWalletJournalRow(transaction: transaction)
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
			tableView.backgroundView = treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: walletJournal?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private var walletJournal: NCCachedResult<[ESI.Wallet.WalletJournalItem]>?
		
}
