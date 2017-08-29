//
//  NCSplitViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit


class NCSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
	
	override func awakeFromNib() {
		super.awakeFromNib()
		delegate = self
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		preferredDisplayMode = .allVisible
		maximumPrimaryColumnWidth = 375
	}
	
	private weak var detailViewController: UIViewController?
	
	override public var preferredStatusBarStyle: UIStatusBarStyle {
		get {
			return self.viewControllers[0].preferredStatusBarStyle
		}
	}
	
	func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewControllerDisplayMode) {
		if traitCollection.userInterfaceIdiom == .phone && viewControllers.count == 2 {
			setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: displayMode == .primaryHidden ? traitCollection.horizontalSizeClass : .compact), forChildViewController: viewControllers[1])
		}
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		(primaryViewController as? UINavigationController)?.isNavigationBarHidden = false
		(secondaryViewController as? UINavigationController)?.viewControllers.first?.navigationItem.leftBarButtonItem = nil
		return secondaryViewController is NCSplashScreenViewController
	}
	
	public func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
		(detailViewController as? UINavigationController)?.viewControllers.first?.navigationItem.leftBarButtonItem = displayModeButtonItem
		return nil
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
		detailViewController = vc
		
		if traitCollection.userInterfaceIdiom == .phone {
			setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: .compact), forChildViewController: vc)
		}
		preferredDisplayMode = vc is NCSplashScreenViewController ? .allVisible : .automatic
		if traitCollection.horizontalSizeClass == .regular {
			(vc as? UINavigationController)?.viewControllers.first?.navigationItem.leftBarButtonItem = displayModeButtonItem
		}
		return false
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		guard viewControllers.count == 2 else {return}
		if traitCollection.userInterfaceIdiom == .phone {
			setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: .compact), forChildViewController: viewControllers[1])
		}
	}
	
}
