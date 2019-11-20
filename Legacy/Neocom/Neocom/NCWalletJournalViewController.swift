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
	var wallet: Wallet = .character
	
	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		tableView.register([Prototype.NCHeaderTableViewCell.default])

		switch wallet {
		case .character:
			let label = NCNavigationItemTitleLabel(frame: CGRect(origin: .zero, size: .zero))
			label.set(title: NSLocalizedString("Wallet Journal", comment: ""), subtitle: nil)
			navigationItem.titleView = label
		case let .corporation(wallet):
			title = wallet.name ?? String(format: NSLocalizedString("Division %d", comment: ""), wallet.division ?? 0)
		}
	}
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		switch wallet {
		case .character:
			let progress = Progress(totalUnitCount: 2)
			return OperationQueue().async { () -> (CachedValue<[ESI.Wallet.WalletJournalItem]>, CachedValue<Double>) in
				let walletJournal = progress.perform{self.dataManager.walletJournal()}
				let walletBalance = progress.perform{self.dataManager.walletBalance()}
				return try (walletJournal.get(), walletBalance.get())
			}.then(on: .main) { result -> [NCCacheRecord] in
				self.walletJournal = result.0
				self.walletBalance = result.1
				return [result.0.cacheRecord(in: NCCache.sharedCache!.viewContext), result.1.cacheRecord(in: NCCache.sharedCache!.viewContext)]
			}
		case let .corporation(wallet):
			return Progress(totalUnitCount: 1).perform {
				self.dataManager.corpWalletJournal(division: wallet.division ?? 0).then(on: .main) { result -> [NCCacheRecord] in
					self.corpWalletJournal = result
					return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
				}
			}
		}
	}
	
	override func content() -> Future<TreeNode?> {
		if let value = walletBalance?.value {
			let label = navigationItem.titleView as? NCNavigationItemTitleLabel
			label?.set(title: NSLocalizedString("Wallet Journal", comment: ""), subtitle: NCUnitFormatter.localizedString(from: value, unit: .isk, style: .full))
		}
		let walletJournal = self.walletJournal
		let corpWalletJournal = self.corpWalletJournal
		return DispatchQueue.global(qos: .utility).async { () -> TreeNode? in
			guard let value: [NCWalletJournalItem] = walletJournal?.value ?? corpWalletJournal?.value else {throw NCTreeViewControllerError.noResult}
			
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
				
				let row = NCWalletJournalRow(item: transaction)
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
			guard !sections.isEmpty else {throw NCTreeViewControllerError.noResult}
			return RootNode(sections)
		}
	}
	
	private var walletJournal: CachedValue<[ESI.Wallet.WalletJournalItem]>?
	private var corpWalletJournal: CachedValue<[ESI.Wallet.CorpWalletsJournalItem]>?
	private var walletBalance: CachedValue<Double>?
	
}
