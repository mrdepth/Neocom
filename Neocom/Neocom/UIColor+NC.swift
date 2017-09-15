//
//  UIColor+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

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
	
	var css:String {
		let rgba = UnsafeMutablePointer<CGFloat>.allocate(capacity: 4)
		defer {rgba.deallocate(capacity: 4)}
		getRed(&rgba[0], green: &rgba[1], blue: &rgba[2], alpha: &rgba[3])
		return String(format: "#%.2x%.2x%.2x", Int(rgba[0] * 255.0), Int(rgba[1] * 255.0), Int(rgba[2] * 255.0))
	}
}
