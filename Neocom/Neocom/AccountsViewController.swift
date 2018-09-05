//
//  AccountsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class AccountsViewController: TreeViewController<AccountsPresenter>, TreeView, UIViewControllerTransitioningDelegate {
//	typealias Presenter = AccountsPresenter
//
//	lazy var presenter: Presenter! = Presenter(view: self)
//	var unwinder: Unwinder?
//	lazy var treeController: TreeController! = TreeController()
	
	@IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!

	override func viewDidLoad() {
		super.viewDidLoad()
		panGestureRecognizer.isEnabled = false
	}
	
	@IBAction func onPan(_ sender: UIPanGestureRecognizer) {
		presenter.onPan(sender)
	}

	//MARK: - UIViewControllerTransitioningDelegate
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return SlideDownAnimationController()
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		let isInteractive = panGestureRecognizer.state == .changed || panGestureRecognizer.state == .began
		return isInteractive ? SlideDownInteractiveTransition(panGestureRecognizer: panGestureRecognizer) : nil
	}
}

//extension AccountsViewController: UIGestureRecognizerDelegate {
//
//	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//		guard !isEditing else {return false}
//		guard let t = (gestureRecognizer as? UIPanGestureRecognizer)?.translation(in: view) else {return true}
//
//		if #available(iOS 11.0, *) {
//			if tableView.bounds.maxY < tableView.contentSize.height + tableView.adjustedContentInset.bottom {
//				return false
//			}
//		} else {
//			if tableView.bounds.maxY < tableView.contentSize.height + tableView.contentInset.bottom {
//				return false
//			}
//		}
//		return t.y < 0
//	}
//
//	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//		return true
//	}
//
//}
