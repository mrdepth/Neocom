//
//  NCNavigationController.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCNavigationController: UINavigationController {
	
	override init(rootViewController: UIViewController) {
		super.init(rootViewController: rootViewController)
		navigationBar.isTranslucent = false
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
	}
	
//	override func setToolbarHidden(_ hidden: Bool, animated: Bool) {
//		super.setToolbarHidden(hidden, animated: animated)
//		if #available(iOS 11.0, *) {
//			sequence(first: self, next: {$0.parent}).forEach {
//				print("\($0.additionalSafeAreaInsets)")
//			}
//			print("\(toolbar.frame) \(self.additionalSafeAreaInsets)")
//		} else {
//			// Fallback on earlier versions
//		}
//	}
}
