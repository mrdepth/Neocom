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
