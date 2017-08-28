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
	
	override public var preferredStatusBarStyle: UIStatusBarStyle {
		get {
			return self.viewControllers[0].preferredStatusBarStyle
		}
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		(primaryViewController as? UINavigationController)?.isNavigationBarHidden = false
		return false
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
		if traitCollection.userInterfaceIdiom == .phone {
			setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: .compact), forChildViewController: vc)
		}
		return false
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		if traitCollection.userInterfaceIdiom == .phone && viewControllers.count == 2 {
			setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: .compact), forChildViewController: viewControllers[1])
		}
	}
}
