//
//  UIImage+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

extension UIImage {
	class func image(color: UIColor, size: CGSize = CGSize(width: 1, height: 1), scale: CGFloat = 1) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(size, false, scale);
		color.setFill()
		UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
		let image = UIGraphicsGetImageFromCurrentImageContext()!;
		UIGraphicsEndImageContext();
		return image.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: UIImageResizingMode.tile)
	}
	
	class func searchFieldBackgroundImage(color: UIColor) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(CGSize(width: 28, height: 28), false, UIScreen.main.scale);
		color.setFill()
		UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 28, height: 28), cornerRadius: 5).fill()
		let image = UIGraphicsGetImageFromCurrentImageContext()!;
		UIGraphicsEndImageContext();
		return image.resizableImage(withCapInsets: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), resizingMode: UIImageResizingMode.stretch)
	}
}
