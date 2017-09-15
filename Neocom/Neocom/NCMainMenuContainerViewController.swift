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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		updateHeader()
		
		boundsObserver = mainMenuViewController?.tableView.observe(\UITableView.bounds) { [weak self] (tableView, change) in
			guard let strongSelf = self, let tableHeaderView = strongSelf.mainMenuViewController?.tableView.tableHeaderView else {return}
			let rect = tableHeaderView.convert(tableHeaderView.bounds, to: strongSelf.view)
			strongSelf.headerHeightConstraint?.constant = max(rect.maxY, 0)
		}

	}
	
	private var boundsObserver: NSKeyValueObservation?
	
	deinit {
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
			self.mainMenuViewController?.tableView.tableHeaderView?.frame = rect
			self.mainMenuViewController?.tableView.tableHeaderView = self.mainMenuViewController?.tableView.tableHeaderView

			addChildViewController(to)
			view.addSubview(to.view)
			to.didMove(toParentViewController: self)
		}
		
		self.headerViewController = to;
		
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": to.view]))
		to.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
		headerHeightConstraint = to.view.heightAnchor.constraint(equalToConstant: headerMaxHeight)
		headerHeightConstraint?.priority = UILayoutPriority(900)
		headerHeightConstraint?.isActive = true
		to.view.heightAnchor.constraint(greaterThanOrEqualToConstant: headerMinHeight).isActive = true
		headerMaxHeightConstraint = to.view.heightAnchor.constraint(lessThanOrEqualToConstant: headerMaxHeight)
		headerMaxHeightConstraint?.isActive = true
	}
}
