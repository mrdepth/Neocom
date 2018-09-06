//
//  AccountsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class AccountsViewController: TreeViewController<AccountsPresenter>, TreeView, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {
//	typealias Presenter = AccountsPresenter
//
//	lazy var presenter: Presenter! = Presenter(view: self)
//	var unwinder: Unwinder?
//	lazy var treeController: TreeController! = TreeController()
	
	@IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!

	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.rightBarButtonItem = editButtonItem
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		navigationController?.transitioningDelegate = self
	}
	
	@IBAction func onPan(_ sender: UIPanGestureRecognizer) {
		presenter.onPan(sender)
	}

	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		if !editing {
		}
		navigationController?.setToolbarHidden(!editing, animated: true)
		updateTitle()
	}
	
	//MARK: - UIViewControllerTransitioningDelegate
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return SlideDownAnimationController()
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		let isInteractive = panGestureRecognizer.state == .changed || panGestureRecognizer.state == .began
		return isInteractive ? SlideDownInteractiveTransition(panGestureRecognizer: panGestureRecognizer) : nil
	}

	override func treeController<T>(_ treeController: TreeController, canEdit item: T) -> Bool where T : TreeItem {
		return presenter.canEdit(item)
	}

	
	override func treeController<T>(_ treeController: TreeController, editingStyleFor item: T) -> UITableViewCell.EditingStyle where T : TreeItem {
		return presenter.editingStyle(for: item)
	}
	
	override func treeController<T>(_ treeController: TreeController, commit editingStyle: UITableViewCell.EditingStyle, for item: T) where T : TreeItem {
		presenter.commit(editingStyle: editingStyle, for: item)
	}
	
	//MARK: - UIGestureRecognizerDelegate
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard !isEditing else {return false}
		guard let t = (gestureRecognizer as? UIPanGestureRecognizer)?.translation(in: view) else {return true}
		
		if #available(iOS 11.0, *) {
			if tableView.bounds.maxY < tableView.contentSize.height + tableView.adjustedContentInset.bottom {
				return false
			}
		} else {
			if tableView.bounds.maxY < tableView.contentSize.height + tableView.contentInset.bottom {
				return false
			}
		}
		return t.y < 0
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
	
	//MARK: - Private
	
}

extension AccountsViewController {
	private func updateTitle() {
		if isEditing {
			let n = treeController.selectedItems()?.count ?? 0
			title = n > 0 ? String.localizedStringWithFormat(NSLocalizedString("Selected %d Accounts", comment: ""), n) : NSLocalizedString("Accounts", comment: "")
			//			toolbarItems?.first?.isEnabled = n > 0
			//			toolbarItems?.last?.isEnabled = n > 0

			toolbarItems?[0].title = n > 0 ? NSLocalizedString("Move To", comment: "") : NSLocalizedString("Folders", comment: "")
		}
		else {
			title = NSLocalizedString("Accounts", comment: "")
		}
	}
}
