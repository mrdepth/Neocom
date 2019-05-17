//
//  NCAccountsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI
import Futures

class NCAccountsViewController: NCTreeViewController {
	@IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.rightBarButtonItem = editButtonItem
		
		tableView.register([Prototype.NCActionTableViewCell.default,
		                    Prototype.NCAccountTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.empty,
							Prototype.NCDefaultTableViewCell.noImage])
		
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		navigationController?.transitioningDelegate = self
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		guard let context = NCStorage.sharedStorage?.viewContext else {return}
		if context.hasChanges {
			try? context.save()
		}
	}

	
	@IBAction func onDelete(_ sender: UIBarButtonItem) {
		guard let selected = treeController?.selectedNodes().compactMap ({$0 as? NCAccountRow}) else {return}
		guard !selected.isEmpty else {return}
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		controller.addAction(UIAlertAction(title: String(format: NSLocalizedString("Delete %d Accounts", comment: ""), selected.count), style: .destructive) { [weak self] _ in
			selected.forEach {
				$0.object.managedObjectContext?.delete($0.object)
			}
			if let context = selected.first?.object.managedObjectContext, context.hasChanges {
				try? context.save()
			}
			self?.updateTitle()
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		
		present(controller, animated: true, completion: nil)
		controller.popoverPresentationController?.barButtonItem = sender
	}
	
	@IBAction func onMoveTo(_ sender: Any) {
		guard let selected = treeController?.selectedNodes().compactMap ({$0 as? NCAccountRow}) else {return}
		guard !selected.isEmpty else {return}

		Router.Account.AccountsFolderPicker { [weak self] (controller, folder) in
			controller.dismiss(animated: true, completion: nil)
			selected.forEach {
				$0.object.folder = folder
			}
			
			let account: NCAccount?
			if let folder = folder {
				account = folder.managedObjectContext?.fetch("Account", limit: 1, sortedBy: [NSSortDescriptor(key: "order", ascending: false)], where: "folder == %@", folder)
			}
			else {
				account = selected.first?.object.managedObjectContext?.fetch("Account", limit: 1, sortedBy: [NSSortDescriptor(key: "order", ascending: false)], where: "folder == nil")
			}
			
			var order = account != nil ? account!.order : 0
			
			selected.forEach {
				$0.object.order = order
				order += 1
			}
			
			if let context = selected.first?.object.managedObjectContext, context.hasChanges {
				try? context.save()
			}
			self?.updateTitle()

		}.perform(source: self, sender: sender)
	}
	
	@IBAction func onFolders(_ sender: Any) {
		guard let selected = treeController?.selectedNodes().compactMap ({$0 as? NCAccountRow}) else {return}

		if selected.isEmpty {
			Router.Account.Folders().perform(source: self, sender: sender)
		}
		else {
			Router.Account.AccountsFolderPicker { [weak self] (controller, folder) in
				controller.dismiss(animated: true, completion: nil)
				selected.forEach {
					$0.object.folder = folder
				}
				
				let account: NCAccount?
				if let folder = folder {
					account = folder.managedObjectContext?.fetch("Account", limit: 1, sortedBy: [NSSortDescriptor(key: "order", ascending: false)], where: "folder == %@", folder)
				}
				else {
					account = selected.first?.object.managedObjectContext?.fetch("Account", limit: 1, sortedBy: [NSSortDescriptor(key: "order", ascending: false)], where: "folder == nil")
				}
				
				var order = account != nil ? account!.order : 0
				
				selected.forEach {
					$0.object.order = order
					order += 1
				}
				
				if let context = selected.first?.object.managedObjectContext, context.hasChanges {
					try? context.save()
				}
				self?.updateTitle()
				
				}.perform(source: self, sender: sender)
		}
	}

	
	@IBAction func onClose(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		if !editing {
			guard let context = NCStorage.sharedStorage?.viewContext else {return}
			if context.hasChanges {
				try? context.save()
			}
		}
		navigationController?.setToolbarHidden(!editing, animated: true)
		updateTitle()
	}
	
//	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//		guard !isEditing else {return}
//
//		let bottom = max(scrollView.contentSize.height - scrollView.bounds.size.height, 0)
//		let y = scrollView.contentOffset.y - bottom
//		if (y > 40 && transitionCoordinator == nil && scrollView.isTracking) {
//			self.isInteractive = true
//			dismiss(animated: true, completion: nil)
//			self.isInteractive = false
//		}
//	}
	
	private var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
	
	override func content() -> Future<TreeNode?> {
		guard let context = NCStorage.sharedStorage?.viewContext else {return .init(nil)}
		let row = NCActionRow(title: NSLocalizedString("SIGN IN", comment: ""))
		let space = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty)
		return .init(RootNode([NCAccountsNode<NCAccountRow>(context: context, cachePolicy: cachePolicy), space, row], collapseIdentifier: "NCAccountsViewController"))
	}
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		self.cachePolicy = cachePolicy
		return .init([])
	}
	
	// MARK: TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		if isEditing {
			if !(node is NCAccountRow) {
				treeController.deselectCell(for: node, animated: true)
			}
			updateTitle()
		}
		else {
			treeController.deselectCell(for: node, animated: true)
			if node is NCActionRow {
				ESI.performAuthorization(from: self)
//				if #available(iOS 10.0, *) {
//					UIApplication.shared.open(url, options: [:], completionHandler: nil)
//				} else {
//					UIApplication.shared.openURL(url)
//				}
			}
			else if let node = node as? NCAccountRow {
				NCAccount.current = node.object
				dismiss(animated: true, completion: nil)
			}
		}
	}
	
	override func treeController(_ treeController: TreeController, didDeselectCellWithNode node: TreeNode) {
		super.treeController(treeController, didDeselectCellWithNode: node)
		if isEditing {
			updateTitle()
		}
	}
	
	func treeController(_ treeController: TreeController, didCollapseCellWithNode node: TreeNode) {
		updateTitle()
		
	}
	
	func treeController(_ treeController: TreeController, didExpandCellWithNode node: TreeNode) {
		updateTitle()
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCAccountRow else {return nil}
		return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { [weak self] (_,_) in
			let account = node.object
			account.managedObjectContext?.delete(account)
			try? account.managedObjectContext?.save()
			self?.updateTitle()
		})]
	}
	
	func treeController(_ treeController: TreeController, didMoveNode node: TreeNode, at: Int, to: Int) {
		var order: Int32 = 0
		(node.parent?.children as? [NCAccountRow])?.forEach {
			if $0.object.order != order {
				$0.object.order = order
			}
			order += 1
		}
	}
	
	@IBAction func onPan(_ sender: UIPanGestureRecognizer) {
		if sender.state == .began && sender.translation(in: view).y < 0 {
			dismiss(animated: true, completion: nil)
		}
	}
	
	// MARK: UIViewControllerTransitioningDelegate
	private var isInteractive: Bool = false

	
	//MARK: - Private
	
	private func updateTitle() {
		if isEditing {
			let n = treeController?.selectedNodes().count ?? 0
			title = n > 0 ? String(format: NSLocalizedString("Selected %d Accounts", comment: ""), n) : NSLocalizedString("Accounts", comment: "")
//			toolbarItems?.first?.isEnabled = n > 0
//			toolbarItems?.last?.isEnabled = n > 0
			
			toolbarItems?[0].title = n > 0 ? NSLocalizedString("Move To", comment: "") : NSLocalizedString("Folders", comment: "")
		}
		else {
			title = NSLocalizedString("Accounts", comment: "")
		}
	}
}

extension NCAccountsViewController: UIViewControllerTransitioningDelegate {
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return NCSlideDownAnimationController()
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		let isInteractive = panGestureRecognizer.state == .changed || panGestureRecognizer.state == .began
		return isInteractive ? NCSlideDownInteractiveTransition(panGestureRecognizer: panGestureRecognizer) : nil
	}
}

extension NCAccountsViewController: UIGestureRecognizerDelegate {
	
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
