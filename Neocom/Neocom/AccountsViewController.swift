//
//  AccountsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import CoreData

class AccountsViewController: TreeViewController<AccountsPresenter>, TreeView, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {
	
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

	@IBAction func onDelete(_ sender: Any) {
		
		let items = treeController.selectedItems()?.compactMap({ i -> NSManagedObject? in (i as? Tree.Item.AccountsItem)?.result ?? (i as? Tree.Item.AccountsFolderItem)?.result})
		presenter.onDelete(items: items ?? []).then(on: .main) { [weak self] _ in
			self?.updateSelection()
		}
	}

	@IBAction func onNewFolder(_ sender: Any) {
		presenter.onNewFolder()
	}

	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		if !editing {
			try? Services.storage.viewContext.save()
		}
		navigationController?.setToolbarHidden(!editing, animated: true)
		updateSelection()
	}
	
	override func treeController<T>(_ treeController: TreeController, canEdit item: T) -> Bool where T : TreeItem {
		return presenter.canEdit(item)
	}
	
	override func treeController<T>(_ treeController: TreeController, configure cell: UITableViewCell, for item: T) where T : TreeItem {
		super.treeController(treeController, configure: cell, for: item)
		if let folderItem = item as? Tree.Item.AccountsFolderItem, let cell = cell as? TreeHeaderCell {
			cell.editingAction = cell.editingButton.map{ActionHandler($0, for: .touchUpInside, handler: { [weak self] (_) in
				self?.presenter.onFolderActions(folderItem.result)
			})}
		}
	}
	
	override func treeController<T>(_ treeController: TreeController, editingStyleFor item: T) -> UITableViewCell.EditingStyle where T : TreeItem {
		return presenter.editingStyle(for: item)
	}
	
	override func treeController<T>(_ treeController: TreeController, commit editingStyle: UITableViewCell.EditingStyle, for item: T) where T : TreeItem {
		presenter.commit(editingStyle: editingStyle, for: item)
	}
	
	override func treeController<T>(_ treeController: TreeController, editActionsFor item: T) -> [UITableViewRowAction]? where T : TreeItem {
		return presenter.editActions(for: item)
	}
	
	override func treeController<T>(_ treeController: TreeController, canMove item: T) -> Bool where T : TreeItem {
		return presenter.canMove(item)
	}
	
	override func treeController<T, S, D>(_ treeController: TreeController, canMove item: T, at fromIndex: Int, inParent oldParent: S?, to toIndex: Int, inParent newParent: D?) -> Bool where T : TreeItem, S : TreeItem, D : TreeItem {
		return presenter.canMove(item, at: fromIndex, inParent: oldParent, to: toIndex, inParent: newParent)
	}
	
	override func treeController<T, S, D>(_ treeController: TreeController, move item: T, at fromIndex: Int, inParent oldParent: S?, to toIndex: Int, inParent newParent: D?) where T : TreeItem, S : TreeItem, D : TreeItem {
		presenter.move(item, at: fromIndex, inParent: oldParent, to: toIndex, inParent: newParent)
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		if isEditing {
			updateSelection()
		}
		else {
			presenter.didSelect(item: item)
			treeController.deselectCell(for: item, animated: true)
		}
	}
	
	override func treeController<T>(_ treeController: TreeController, didDeselectRowFor item: T) where T : TreeItem {
		updateSelection()
	}

	
	//MARK: - UIViewControllerTransitioningDelegate
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return SlideDownAnimationController()
	}
	
	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		let isInteractive = panGestureRecognizer.state == .changed || panGestureRecognizer.state == .began
		return isInteractive ? SlideDownInteractiveTransition(panGestureRecognizer: panGestureRecognizer) : nil
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
	
}

extension AccountsViewController {
//	private func updateTitle() {
//		if isEditing {
//			let n = treeController.selectedItems()?.count ?? 0
//			title = n > 0 ? String.localizedStringWithFormat(NSLocalizedString("Selected %d Accounts", comment: ""), n) : NSLocalizedString("Accounts", comment: "")
//			//			toolbarItems?.first?.isEnabled = n > 0
//			//			toolbarItems?.last?.isEnabled = n > 0
//
////			toolbarItems?[0].title = n > 0 ? NSLocalizedString("Move To", comment: "") : NSLocalizedString("Folders", comment: "")
//		}
//		else {
//			title = NSLocalizedString("Accounts", comment: "")
//		}
//	}
	
	private func updateSelection() {
		let selected = treeController.selectedItems()?.count ?? 0
		if selected > 0 {
			toolbarItems?.last?.title = String.localizedStringWithFormat(NSLocalizedString("Delete (%d)", comment: ""), selected)
			toolbarItems?.last?.isEnabled = true
		}
		else {
			toolbarItems?.last?.title = NSLocalizedString("Delete", comment: "")
			toolbarItems?.last?.isEnabled = false
		}
	}
}
