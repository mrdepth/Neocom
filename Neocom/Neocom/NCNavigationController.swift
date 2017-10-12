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
}
