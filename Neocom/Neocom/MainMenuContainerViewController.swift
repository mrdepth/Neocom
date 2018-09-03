//
//  MainMenuContainerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import Expressible

class MainMenuContainerViewController: UIViewController {
	lazy var mainMenuViewController: MainMenuViewController? = {
		return self.children.first as? MainMenuViewController
	}()
	
	private var headerViewController: MainMenuHeaderViewController?
	private var headerHeightConstraint: NSLayoutConstraint?
	private var headerMaxHeightConstraint: NSLayoutConstraint?
	
	@IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
	@IBOutlet weak var stackView: UIStackView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		updateHeader()
		
		boundsObserver = mainMenuViewController?.tableView.observe(\UITableView.bounds) { [weak self] (tableView, change) in
			guard let strongSelf = self, let tableHeaderView = strongSelf.mainMenuViewController?.tableView.tableHeaderView else {return}
			let rect = tableHeaderView.convert(tableHeaderView.bounds, to: strongSelf.view)
			strongSelf.headerHeightConstraint?.constant = max(rect.maxY, 0)
		}
		
//		NotificationCenter.default.addObserver(self, selector: #selector(currentAccountChanged(_:)), name: .NCCurrentAccountChanged, object: nil)
//		NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: nil)
	}
	
	@IBAction func onTap(_ sender: Any) {
		if Services.storage.viewContext.currentAccount != nil {
		}
		else if let count = try? Services.storage.viewContext.managedObjectContext.from(Account.self).count(), count > 0 {
		}
		else {
		}
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
		let from = self.headerViewController

		let to: MainMenuHeader
		
		if Services.storage.viewContext.currentAccount != nil {
			to = MainMenuHeader.character
		}
		else if let count = try? Services.storage.viewContext.managedObjectContext.from(Account.self).count(), count > 0 {
			to = MainMenuHeader.login
		}
		else {
			to = MainMenuHeader.default
		}
		
		to.instantiate().then(on: .main) { to in
			let headerMinHeight = to.view.systemLayoutSizeFitting(CGSize(width:self.view.bounds.size.width, height:0), withHorizontalFittingPriority:UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.defaultHigh).height
			self.headerMaxHeight = to.view.systemLayoutSizeFitting(CGSize(width:self.view.bounds.size.width, height:0), withHorizontalFittingPriority:UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel).height
			
			let rect = CGRect(origin: CGPoint.zero, size: CGSize(width: self.view.bounds.size.width, height: self.headerMaxHeight))
			
			to.view.frame = rect
			to.view.translatesAutoresizingMaskIntoConstraints = false
			to.view.layoutIfNeeded()
			
			if let from = from {
				from.willMove(toParent: nil)
				self.addChild(to)
				to.view.alpha = 0.0;
				self.transition(from: from, to: to, duration: 0.25, options: [], animations: {
					from.view.alpha = 0.0;
					to.view.alpha = 1.0;
					self.mainMenuViewController?.tableView.tableHeaderView?.frame = rect
					self.mainMenuViewController?.tableView.tableHeaderView = self.mainMenuViewController?.tableView.tableHeaderView
				}, completion: { (fihisned) in
					from.removeFromParent()
					to.didMove(toParent: self)
				})
			}
			else {
				self.mainMenuViewController?.tableView.tableHeaderView?.frame = rect
				self.mainMenuViewController?.tableView.tableHeaderView = self.mainMenuViewController?.tableView.tableHeaderView
				
				self.addChild(to)
				self.view.addSubview(to.view)
				to.didMove(toParent: self)
			}
			
			self.headerViewController = to
			
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": to.view]))
			to.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
			self.headerHeightConstraint = to.view.heightAnchor.constraint(equalToConstant: self.headerMaxHeight)
			self.headerHeightConstraint?.priority = UILayoutPriority(900)
			self.headerHeightConstraint?.isActive = true
			to.view.heightAnchor.constraint(greaterThanOrEqualToConstant: headerMinHeight).isActive = true
			if #available(iOS 11.0, *) {
				//			headerMaxHeightConstraint = to.view.heightAnchor.constraint(lessThanOrEqualToConstant: headerMaxHeight + view.safeAreaInsets.top)
			} else {
				//			headerMaxHeightConstraint = to.view.heightAnchor.constraint(lessThanOrEqualToConstant: headerMaxHeight + topLayoutGuide.length)
			}
			self.headerMaxHeightConstraint?.isActive = true
		}
	}
}
