//
//  NCWalletJournalViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCWalletJournalViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
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
	private var walletJournal: NCCachedResult<EVE.Char.WalletJournal>?
	private var refTypes: NCCachedResult<EVE.Eve.RefTypes>?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		
		let progress = Progress(totalUnitCount: 2)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		
		let dispatchGroup = DispatchGroup()
		
		dispatchGroup.enter()
		progress.perform {
			dataManager.refTypes { result in
				self.refTypes = result
				dispatchGroup.leave()
			}
		}
		
		dispatchGroup.enter()
		progress.perform {
			dataManager.walletJournal { result in
				self.walletJournal = result
				
				switch result {
				case let .success(_, record):
					if let record = record {
						self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
							self?.reloadSections()
						}
					}
				case .failure:
					break
				}
				dispatchGroup.leave()
			}
		}
		
		dispatchGroup.notify(queue: .main) {
			self.reloadSections()
			completionHandler?()
		}
	}
	
	private func reloadSections() {
		if let value = walletJournal?.value {
			let refTypes = self.refTypes?.value
			
			DispatchQueue.global(qos: .background).async {
				autoreleasepool {
					var names: [Int: EVE.Eve.RefTypes.RefType] = [:]
					refTypes?.refTypes.forEach {
						names[$0.refTypeID] = $0
					}
					
					let dateFormatter = DateFormatter()
					dateFormatter.dateStyle = .medium
					dateFormatter.timeStyle = .none
					dateFormatter.doesRelativeDateFormatting = true
					
					let transactions = value.transactions.sorted {$0.date > $1.date}
					let calendar = Calendar(identifier: .gregorian)
					
					var date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: Date())) ?? Date()
					
					var sections = [TreeNode]()
					
					var rows = [NCWalletJournalRow]()
					for transaction in transactions {
						let row = NCWalletJournalRow(transaction: transaction, refType: names[transaction.refTypeID])
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
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: walletJournal?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
	
}
