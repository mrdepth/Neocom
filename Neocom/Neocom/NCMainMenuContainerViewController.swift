//
//  NCMainMenuContainerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.09.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

class NCMainMenuContainerViewController: UIViewController {
	lazy var mainMenuViewController: NCMainMenuViewController? = {
		return self.childViewControllers.first as? NCMainMenuViewController
	}()
	
	private var headerViewController: NCMainMenuHeaderViewController?
	private var headerHeightConstraint: NSLayoutConstraint?
	private var headerMaxHeightConstraint: NSLayoutConstraint?
	
	@IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		updateHeader()
		
		boundsObserver = mainMenuViewController?.tableView.observe(\UITableView.bounds) { [weak self] (tableView, change) in
			guard let strongSelf = self, let tableHeaderView = strongSelf.mainMenuViewController?.tableView.tableHeaderView else {return}
			let rect = tableHeaderView.convert(tableHeaderView.bounds, to: strongSelf.view)
			strongSelf.headerHeightConstraint?.constant = max(rect.maxY, 0)
		}

		NotificationCenter.default.addObserver(self, selector: #selector(currentAccountChanged(_:)), name: .NCCurrentAccountChanged, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: nil)
	}
	
	private var boundsObserver: NSKeyValueObservation?
	
	deinit {
		NotificationCenter.default.removeObserver(self)
		boundsObserver?.invalidate()
		boundsObserver = nil
	}
	
	override func viewLayoutMarginsDidChange() {
		if #available(iOS 11.0, *) {
			headerMaxHeightConstraint?.constant = headerMaxHeight + self.view.safeAreaInsets.top
			mainMenuViewController?.tableView.tableHeaderView?.frame.size.height = headerMaxHeight
			mainMenuViewController?.tableView.tableHeaderView = self.mainMenuViewController?.tableView.tableHeaderView
			super.viewLayoutMarginsDidChange()
		}
	}
	
	private var headerMaxHeight: CGFloat = 0
	
	private func updateHeader() {
		let identifier: String
		if NCAccount.current != nil {
			identifier = "NCMainMenuCharacterHeaderViewController"
		}
		else {
			identifier = (try? NCStorage.sharedStorage!.viewContext.count(for: NSFetchRequest<NCAccount>(entityName: "Account"))) ?? 0 > 0 ? "NCMainMenuLoginHeaderViewController" : "NCMainMenuHeaderViewController"
		}
		
		let from = self.headerViewController
		let to = self.storyboard!.instantiateViewController(withIdentifier: identifier) as! NCMainMenuHeaderViewController
		
		let headerMinHeight = to.view.systemLayoutSizeFitting(CGSize(width:self.view.bounds.size.width, height:0), withHorizontalFittingPriority:UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.defaultHigh).height
		headerMaxHeight = to.view.systemLayoutSizeFitting(CGSize(width:self.view.bounds.size.width, height:0), withHorizontalFittingPriority:UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel).height
		
		let rect = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.bounds.size.width, height: headerMaxHeight))
		
		to.view.frame = rect
		to.view.translatesAutoresizingMaskIntoConstraints = false
		to.view.layoutIfNeeded()
		
		if let from = from {
			from.willMove(toParentViewController: nil)
			addChildViewController(to)
			to.view.alpha = 0.0;
			transition(from: from, to: to, duration: 0.25, options: [], animations: {
				from.view.alpha = 0.0;
				to.view.alpha = 1.0;
				self.mainMenuViewController?.tableView.tableHeaderView?.frame = rect
				self.mainMenuViewController?.tableView.tableHeaderView = self.mainMenuViewController?.tableView.tableHeaderView
			}, completion: { (fihisned) in
				from.removeFromParentViewController()
				to.didMove(toParentViewController: self)
			})
		}
		else {
			mainMenuViewController?.tableView.tableHeaderView?.frame = rect
			mainMenuViewController?.tableView.tableHeaderView = mainMenuViewController?.tableView.tableHeaderView

			addChildViewController(to)
			view.addSubview(to.view)
			to.didMove(toParentViewController: self)
		}
		
		headerViewController = to
		
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": to.view]))
		to.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
		headerHeightConstraint = to.view.heightAnchor.constraint(equalToConstant: headerMaxHeight)
		headerHeightConstraint?.priority = UILayoutPriority(900)
		headerHeightConstraint?.isActive = true
		to.view.heightAnchor.constraint(greaterThanOrEqualToConstant: headerMinHeight).isActive = true
		if #available(iOS 11.0, *) {
//			headerMaxHeightConstraint = to.view.heightAnchor.constraint(lessThanOrEqualToConstant: headerMaxHeight + view.safeAreaInsets.top)
		} else {
//			headerMaxHeightConstraint = to.view.heightAnchor.constraint(lessThanOrEqualToConstant: headerMaxHeight + topLayoutGuide.length)
		}
		headerMaxHeightConstraint?.isActive = true
	}
}

extension NCMainMenuContainerViewController: UIViewControllerTransitioningDelegate {

	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return NCSlideDownAnimationController()
	}
	
	func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
//		guard let tableView = mainMenuViewController?.tableView else {return nil}
//		let isInteractive = tableView.isTracking == true
		let isInteractive = panGestureRecognizer.state == .changed || panGestureRecognizer.state == .began
		return isInteractive ? NCSlideDownInteractiveTransition(panGestureRecognizer: panGestureRecognizer) : nil
	}
	
}

extension NCMainMenuContainerViewController {
	
	@objc func managedObjectContextDidSave(_ note: Notification) {
		guard NCAccount.current == nil else {return}
		guard let viewContext = NCStorage.sharedStorage?.viewContext, let context = note.object as? NSManagedObjectContext else {return}
		guard context.persistentStoreCoordinator === viewContext.persistentStoreCoordinator else {return}
		
		if (note.userInfo?[NSDeletedObjectsKey] as? NSSet)?.contains(where: {$0 is NCAccount}) == true ||
			(note.userInfo?[NSInsertedObjectsKey] as? NSSet)?.contains(where: {$0 is NCAccount}) == true {
			DispatchQueue.main.async {
				self.updateHeader()
			}
		}
	}
	
	@objc func currentAccountChanged(_ note: Notification) {
		updateHeader()
	}
	
	@IBAction func onPan(_ sender: UIPanGestureRecognizer) {
		if sender.state == .began && sender.translation(in: view).y > 0 {
			mainMenuViewController?.performSegue(withIdentifier: "NCAccountsViewController", sender: self)
		}
	}

}


extension NCMainMenuContainerViewController: UIGestureRecognizerDelegate {
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let t = (gestureRecognizer as? UIPanGestureRecognizer)?.translation(in: view) else {return true}
		
		if let tableView: UITableView = view.hitTest(gestureRecognizer.location(in: view), with: nil)?.ancestor() {
			if tableView.contentOffset.y > -tableView.contentInset.top {
				return false
			}
		}
		return t.y > 0
	}
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
	
//	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//		return true
//	}
}
