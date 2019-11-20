//
//  WalletJournalPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

class WalletJournalPageViewController: TreeViewController<WalletJournalPagePresenter, Void>, TreeView {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let label = NavigationItemTitleLabel(frame: CGRect(origin: .zero, size: .zero))
		label.set(title: NSLocalizedString("Wallet Journal", comment: ""), subtitle: nil)
		navigationItem.titleView = label
	}
	
	func present(_ content: WalletJournalPagePresenter.Presentation, animated: Bool) -> Future<Void> {
		
		let label = navigationItem.titleView as? NavigationItemTitleLabel
		label?.set(title: NSLocalizedString("Wallet Journal", comment: ""), subtitle: content.balance)
		
		return treeController.reloadData(content.sections)
	}
	
}
