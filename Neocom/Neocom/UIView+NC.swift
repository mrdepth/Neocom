//
//  UIView+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

extension UIView {
	func ancestor<T:UIView>(of type: T.Type = T.self) -> T? {
		return self as? T ?? self.superview?.ancestor(of: type)
	}
}

extension UITableViewCell {
	var tableView: UITableView? {
		return ancestor(of: UITableView.self)
	}
}

extension UIViewController {
	@IBAction func dismissAnimated(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
	
	var topMostPresentedViewController: UIViewController {
		return presentedViewController?.topMostPresentedViewController ?? self
	}
}

extension UIAlertController {
	convenience init(title: String? = NSLocalizedString("Error", comment: ""), error: Error, handler: ((UIAlertAction) -> Void)? = nil) {
		self.init(title: title, message: error.localizedDescription, preferredStyle: .alert)
		self.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: .default, handler: handler))
	}
}

