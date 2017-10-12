//
//  NCSkillsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCSkillsViewController: UISplitViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		preferredDisplayMode = .allVisible
		preferredPrimaryColumnWidthFraction = 0.5
		maximumPrimaryColumnWidth = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) / 2.0
		
		if traitCollection.horizontalSizeClass == .regular {
			viewControllers.append(storyboard!.instantiateViewController(withIdentifier: "NCSkillsPageViewController"))
		}
		parent?.navigationItem.title = NSLocalizedString("Skills", comment: "")
	}
	
	override func overrideTraitCollection(forChildViewController childViewController: UIViewController) -> UITraitCollection? {
		return traitCollection
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		guard previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass else {return}

		if traitCollection.horizontalSizeClass == .regular {
			if viewControllers.count == 1 {
				viewControllers.append(storyboard!.instantiateViewController(withIdentifier: "NCSkillsPageViewController"))
			}
			parent?.navigationItem.title = NSLocalizedString("Skills", comment: "")
		}
		else {
			parent?.navigationItem.title = viewControllers.first?.navigationItem.title
		}
	}
}
