//
//  MailPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/2/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import EVEAPI

class MailPageViewController: TreeViewController<MailPagePresenter, ESI.Mail.MailLabelsAndUnreadCounts.Label>, TreeView {
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		guard tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 else {return}
		presenter.fetchIfNeeded()
	}
	
	override func treeController<T>(_ treeController: TreeController, canEdit item: T) -> Bool where T : TreeItem {
		return presenter.canEdit(item)
	}
	
	override func treeController<T>(_ treeController: TreeController, editActionsFor item: T) -> [UITableViewRowAction]? where T : TreeItem {
		return presenter.editActions(for: item)
	}
	
	override func treeController<T>(_ treeController: TreeController, editingStyleFor item: T) -> UITableViewCell.EditingStyle where T : TreeItem {
		return presenter.editingStyle(for: item)
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}

	func updateTitle() {
		if let unreadCount = input?.unreadCount, unreadCount > 0 {
			title = "\(input?.name ?? "") (\(unreadCount))"
		}
		else {
			title = input?.name
		}
	}
}
