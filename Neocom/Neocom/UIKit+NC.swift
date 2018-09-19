//
//  UIKit+NC.swift
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

extension UIColor {
	convenience init(security: Float) {
		if security >= 1.0 {
			self.init(number: 0x2FEFEFFF)
		}
		else if security >= 0.9 {
			self.init(number: 0x48F0C0FF)
		}
		else if security >= 0.8 {
			self.init(number: 0x00EF47FF)
		}
		else if security >= 0.7 {
			self.init(number: 0x00F000FF)
		}
		else if security >= 0.6 {
			self.init(number: 0x8FEF2FFF)
		}
		else if security >= 0.5 {
			self.init(number: 0xEFEF00FF)
		}
		else if security >= 0.4 {
			self.init(number: 0xD77700FF)
		}
		else if security >= 0.3 {
			self.init(number: 0xF06000FF)
		}
		else if security >= 0.2 {
			self.init(number: 0xF04800FF)
		}
		else if security >= 0.1 {
			self.init(number: 0xD73000FF)
		}
		else {
			self.init(number: 0xF00000FF)
		}
	}
	
	var css: String {
		var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
		getRed(&r, green: &g, blue: &b, alpha: &a)
		return String(format: "#%.2x%.2x%.2x", Int(r * 255.0), Int(g * 255.0), Int(b * 255.0))
	}
}

extension UIImage {
	class func image(color: UIColor, size: CGSize = CGSize(width: 1, height: 1), scale: CGFloat = 1) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(size, false, scale);
		color.setFill()
		UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
		let image = UIGraphicsGetImageFromCurrentImageContext()!;
		UIGraphicsEndImageContext();
		return image.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .tile)
	}
	
	class func searchFieldBackgroundImage(color: UIColor) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(CGSize(width: 28, height: 28), false, UIScreen.main.scale);
		color.setFill()
		UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 28, height: 28), cornerRadius: 5).fill()
		let image = UIGraphicsGetImageFromCurrentImageContext()!;
		UIGraphicsEndImageContext();
		return image.resizableImage(withCapInsets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), resizingMode: .stretch)
	}
}
