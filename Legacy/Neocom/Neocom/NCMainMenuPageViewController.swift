//
//  NCMainMenuPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 16.04.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class NCMainMenuPageViewController: UIPageViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		dataSource = self
		
		setViewControllers([self.storyboard!.instantiateViewController(withIdentifier: "NCMainMenuViewController")], direction: .forward, animated: false, completion: nil)
	}
}



extension NCMainMenuPageViewController: UIPageViewControllerDataSource {
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		if viewController is UINavigationController {
			return self.storyboard!.instantiateViewController(withIdentifier: "NCMainMenuViewController")
		}
		else {
			return nil
		}
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		if viewController is NCMainMenuViewController {
			return self.storyboard!.instantiateViewController(withIdentifier: "NCAccountsViewController")
		}
		else {
			return nil
		}
	}
}
