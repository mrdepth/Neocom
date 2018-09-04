//
//  AccountsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class AccountsViewController: UITableViewController, TreeView {
	lazy var presenter: AccountsPresenter! = AccountsPresenter(view: self)
	var unwinder: Unwinder?
	lazy var treeController: TreeController! = TreeController()
	@IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		treeController.delegate = self
		treeController.tableView = tableView
		presenter.configure()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		presenter.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presenter.viewDidAppear(animated)
		navigationController?.transitioningDelegate = self
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		presenter.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		presenter.viewDidDisappear(animated)
	}
	

	@IBAction func onPan(_ sender: UIPanGestureRecognizer) {
		presenter.onPan(sender)
	}

}

extension AccountsViewController: UIViewControllerTransitioningDelegate {
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return SlideDownAnimationController()
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		let isInteractive = panGestureRecognizer.state == .changed || panGestureRecognizer.state == .began
		return isInteractive ? SlideDownInteractiveTransition(panGestureRecognizer: panGestureRecognizer) : nil
	}
}

extension AccountsViewController: UIGestureRecognizerDelegate {
	
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
	
}
