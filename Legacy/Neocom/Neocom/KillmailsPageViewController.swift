//
//  KillmailsPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/13/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

class KillmailsPageViewController: TreeViewController<KillmailsPagePresenter, [KillmailsPresenter.Section]>, TreeView {
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!

	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		fetchIfNeeded()
	}
	
	private func fetchIfNeeded() {
		guard tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 else {return}
		activityIndicator.startAnimating()
		presenter.fetchIfNeeded().then(on: .main) { [weak self] in
			self?.activityIndicator.stopAnimating()
			self?.fetchIfNeeded()
		}.catch(on: .main) { [weak self] _ in
			self?.activityIndicator.stopAnimating()
		}
	}
	
	func present(_ content: [Tree.Item.Section<Tree.Content.Section, Tree.Item.KillmailRow>], animated: Bool) -> Future<Void> {
		return treeController.reloadData(content, options: [], with: animated ? .fade : .none).then(on: .main) { [weak self] _ in
			self?.fetchIfNeeded()
		}
	}
}
