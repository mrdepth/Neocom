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

class MainMenuContainerViewController: UIViewController, View {
	lazy var presenter: MainMenuContainerPresenter! = MainMenuContainerPresenter(view: self)
	var unwinder: Unwinder?

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
		presenter.configure()
		
		updateHeader()
		
		boundsObserver = mainMenuViewController?.tableView.observe(\UITableView.bounds) { [weak self] (tableView, change) in
			guard let strongSelf = self, let tableHeaderView = strongSelf.mainMenuViewController?.tableView.tableHeaderView else {return}
			let rect = tableHeaderView.convert(tableHeaderView.bounds, to: strongSelf.view)
			strongSelf.headerHeightConstraint?.constant = max(rect.maxY, 0)
		}
		
//		NotificationCenter.default.addObserver(self, selector: #selector(currentAccountChanged(_:)), name: .NCCurrentAccountChanged, object: nil)
//		NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextDidSave(_:)), name: .NSManagedObjectContextDidSave, object: nil)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		presenter.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presenter.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		presenter.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		presenter.viewDidDisappear(animated)
	}
	
	@IBAction func onTap(_ sender: Any) {
		presenter.onHeaderTap()
	}
	
	@IBAction func onPan(_ sender: UIPanGestureRecognizer) {
		presenter.onPan(sender)
//		if sender.state == .began && sender.translation(in: view).y > 0 {
//			mainMenuViewController?.performSegue(withIdentifier: "NCAccountsViewController", sender: self)
//		}
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
	
	func updateHeader() {
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
			to.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onTap(_:))))
			
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
	
	func prepareToRoute<T>(to view: T) where T : View {
		if let view = view as? AccountsViewController {
			view.parent?.modalPresentationStyle = .currentContext
			view.parent?.transitioningDelegate = self
		}
	}
}

extension MainMenuContainerViewController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return SlideDownAnimationController()
	}
	
	func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		let isInteractive = panGestureRecognizer.state == .changed || panGestureRecognizer.state == .began
		return isInteractive ? SlideDownInteractiveTransition(panGestureRecognizer: panGestureRecognizer) : nil
	}

}

extension MainMenuContainerViewController: UIGestureRecognizerDelegate {
	
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
