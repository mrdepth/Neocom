//
//  ZKillmailsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import EVEAPI
import Futures

class ZKillmailsViewController: TreeViewController<ZKillmailsPresenter, [EVEAPI.ZKillboard.Filter]>, TreeView {
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		fetchIfNeeded()
	}
	
	private func fetchIfNeeded() {
		guard tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 else {return}
		presenter.fetchIfNeeded().then(on: .main) { [weak self] _ in
			self?.fetchIfNeeded()
		}
	}
	
	func present(_ content: [Tree.Item.ZKillmailRow], animated: Bool) -> Future<Void> {
		return treeController.reloadData(content, options: [], with: animated ? .fade : .none).then(on: .main) { [weak self] _ in
			self?.fetchIfNeeded()
		}
	}
	
}
