//
//  WalletJournalPagePresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import EVEAPI

class WalletJournalPagePresenter: TreePresenter {
	typealias View = WalletJournalPageViewController
	typealias Interactor = WalletJournalPageInteractor
	
	struct Presentation {
		var sections: [Tree.Item.Section<Tree.Content.Section, Tree.Item.Row<ESI.Wallet.WalletJournalItem>>]
		var balance: String?
	}

	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeSectionCell.default,
								  Prototype.WalletJournalCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let treeController = view?.treeController
		
		return DispatchQueue.global(qos: .utility).async { () -> Presentation in
			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .medium
			dateFormatter.timeStyle = .none
			dateFormatter.doesRelativeDateFormatting = true
			
			let items = content.value.walletJournal.sorted{$0.date > $1.date}
			let calendar = Calendar(identifier: .gregorian)
			
			let sections = Dictionary(grouping: items, by: { (i) -> Date in
				let components = calendar.dateComponents([.year, .month, .day], from: i.date)
				return calendar.date(from: components) ?? i.date
			}).sorted {$0.key > $1.key}.map {
				Tree.Item.Section(Tree.Content.Section(title: dateFormatter.string(from: $0.key).uppercased()), diffIdentifier: $0.key, treeController: treeController, children: $0.value.map{Tree.Item.Row($0)})
			}
			
			let balance = content.value.balance.map {UnitFormatter.localizedString(from: $0, unit: .isk, style: .long)}
			
			return Presentation(sections: sections, balance: balance)
		}
	}
}
