//
//  SkillsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 19/10/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class SkillsViewController: UISplitViewController, View {
	
	typealias Presenter = SkillsPresenter
	lazy var presenter: Presenter! = Presenter(view: self)
	
	var unwinder: Unwinder?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		presenter.configure()
		
		preferredDisplayMode = .allVisible
		preferredPrimaryColumnWidthFraction = 0.5
		maximumPrimaryColumnWidth = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) / 2.0
		
		if traitCollection.horizontalSizeClass == .regular {
			viewControllers.append(storyboard!.instantiateViewController(withIdentifier: "NCSkillsPageViewController"))
		}
		parent?.navigationItem.title = NSLocalizedString("Skills", comment: "")
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
	
	
	override func overrideTraitCollection(forChild childViewController: UIViewController) -> UITraitCollection? {
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
