//
//  NCWalletTransactionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCWalletTransactionsViewController: NCTreeViewController {
	var wallet: Wallet = .character

	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		
		switch wallet {
		case .character:
			let label = NCNavigationItemTitleLabel(frame: CGRect(origin: .zero, size: .zero))
			label.set(title: NSLocalizedString("Wallet Transactions", comment: ""), subtitle: nil)
			navigationItem.titleView = label
		case let .corporation(wallet):
			title = wallet.name ?? String(format: NSLocalizedString("Division %d", comment: ""), wallet.division ?? 0)
		}
	}
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		switch wallet {
		case .character:
			let progress = Progress(totalUnitCount: 2)
			return DispatchQueue.global(qos: .utility).async { () -> (CachedValue<[ESI.Wallet.Transaction]>, CachedValue<Double>) in
				let walletTransactions = progress.perform{self.dataManager.walletTransactions()}
				let walletBalance = progress.perform{self.dataManager.walletBalance()}
				return try (walletTransactions.get(), walletBalance.get())
			}.then(on: .main) { result -> [NCCacheRecord] in
				self.walletTransactions = result.0
				self.walletBalance = result.1
				return [self.walletTransactions?.cacheRecord(in: NCCache.sharedCache!.viewContext), self.walletBalance?.cacheRecord(in: NCCache.sharedCache!.viewContext)].compactMap {$0}
//				completionHandler([self.walletTransactions?.cacheRecord, self.walletBalance?.cacheRecord].compactMap {$0})
			}
		case let .corporation(wallet):
			return Progress(totalUnitCount: 1).perform {
				self.dataManager.corpWalletTransactions(division: wallet.division ?? 0).then(on: .main) { result -> [NCCacheRecord] in
					self.corpWalletTransactions = result
					return [self.corpWalletTransactions?.cacheRecord(in: NCCache.sharedCache!.viewContext)].compactMap {$0}
				}
			}
		}
	}
	
	override func content() -> Future<TreeNode?> {
		if let value = walletBalance?.value {
			let label = navigationItem.titleView as? NCNavigationItemTitleLabel
			label?.set(title: NSLocalizedString("Wallet Transactions", comment: ""), subtitle: NCUnitFormatter.localizedString(from: value, unit: .isk, style: .full))
		}
		
		let walletTransactions = self.walletTransactions
		let corpWalletTransactions = self.corpWalletTransactions
		let progress = Progress(totalUnitCount: 3)


		return DispatchQueue.global(qos: .utility).async { () -> TreeNode? in
			guard let value: [NCWalletTransaction] = walletTransactions?.value ?? corpWalletTransactions?.value else {throw NCTreeViewControllerError.noResult}
			
			var sections = [TreeNode]()

			let locationIDs = Set(value.map {$0.locationID})
			let contactIDs = Set(value.map{Int64($0.clientID)})
			
			var locations: Future<[Int64: NCLocation]>?
			var contacts: Future<[Int64: NSManagedObjectID]>?

			progress.perform {
				if !contactIDs.isEmpty {
					contacts = self.dataManager.contacts(ids: contactIDs)
				}
			}
			
			progress.perform {
				if !locationIDs.isEmpty {
					locations = self.dataManager.locations(ids: locationIDs)
				}
			}
			
			NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext in
				
				let dateFormatter = DateFormatter()
				dateFormatter.dateStyle = .medium
				dateFormatter.timeStyle = .none
				dateFormatter.doesRelativeDateFormatting = true
				
				let transactions = value.sorted {$0.date > $1.date}
				let calendar = Calendar(identifier: .gregorian)
				
				var date = calendar.date(from: calendar.dateComponents([.day, .month, .year], from: Date())) ?? Date()
				
				
				var rows = [NCWalletTransactionRow]()
				let locations = try? locations?.get()
				let contacts = try? contacts?.get()
				
				for transaction in transactions {
					let row = NCWalletTransactionRow(transaction: transaction, location: locations??[transaction.locationID], clientID: contacts??[Int64(transaction.clientID)])
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
				
			}
			guard !sections.isEmpty else {throw NCTreeViewControllerError.noResult}
			return RootNode(sections)
		}
	}
	
	private var walletTransactions: CachedValue<[ESI.Wallet.Transaction]>?
	private var corpWalletTransactions: CachedValue<[ESI.Wallet.CorpTransaction]>?
	private var walletBalance: CachedValue<Double>?

}
