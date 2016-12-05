//
//  NSAttributedString+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

extension NSAttributedString {
	@nonobjc private static var roman = ["0","I","II","III","IV","V"]
	
	convenience init(skillName: String, level: Int) {
		let s = NSMutableAttributedString(string: skillName)
		let level = level.clamped(to: 0...5)
		s.append(NSAttributedString(string: " \(NSAttributedString.roman[level])", attributes: [NSForegroundColorAttributeName: UIColor.caption]))
		self.init(attributedString: s)
	}
	
	
}
