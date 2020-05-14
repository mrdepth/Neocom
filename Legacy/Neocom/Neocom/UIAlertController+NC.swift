//
//  UIAlertController+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

extension UIViewController {
	var topMostPresentedViewController: UIViewController {
		if let presentedViewController = presentedViewController {
			return presentedViewController.topMostPresentedViewController
		}
		else {
			return self
		}
	}
}

extension UIAlertController {
	convenience init(title: String? = NSLocalizedString("Error", comment: ""), error: Error, handler: ((UIAlertAction) -> Void)? = nil) {
		self.init(title: title, message: error.localizedDescription, preferredStyle: .alert)
		self.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: handler))
	}
}

