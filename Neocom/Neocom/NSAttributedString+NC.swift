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
		let s = NSMutableAttributedString(string: skillName, attributes: [NSForegroundColorAttributeName: UIColor.white])
		let level = level.clamped(to: 0...5)
		s.append(NSAttributedString(string: " \(NSAttributedString.roman[level])", attributes: [NSForegroundColorAttributeName: UIColor.caption]))
		self.init(attributedString: s)
	}
	
	func withFont(_ font: UIFont, textColor: UIColor) -> NSAttributedString {
		let s = self.mutableCopy() as! NSMutableAttributedString
		
		self.enumerateAttributes(in: NSMakeRange(0, self.length), options: [], using: {(attr, range, stop) -> Void in
			var hasFont = false
			var hasColor = false
			for (key, value) in attr {
				switch key {
				case "UIFontDescriptorSymbolicTraits":
					if let traits = value as? UInt32, let fontDescriptor = font.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(rawValue: traits)) {
						let theFont = UIFont(descriptor: fontDescriptor, size: font.pointSize)
						s.addAttribute(NSFontAttributeName, value: theFont, range: range)
						hasFont = true
					}
				case "NSURL":
					if let fontDescriptor = font.fontDescriptor.withSymbolicTraits([.traitBold]) {
						let theFont = UIFont(descriptor: fontDescriptor, size: font.pointSize)
						s.addAttributes([NSFontAttributeName: theFont, NSForegroundColorAttributeName: UIColor.caption], range: range)
						hasFont = true
						hasColor = true
					}
				case NSForegroundColorAttributeName:
					hasColor = true
				case NSFontAttributeName:
					hasFont = true
				default:
					break
				}
			}
			
			if (!hasFont) {
				s.addAttribute(NSFontAttributeName, value: font, range: range)
			}
			if (!hasColor) {
				s.addAttribute(NSForegroundColorAttributeName, value: textColor, range: range)
			}
			
		})
		
		return s
	}
	
	func uppercased() -> NSAttributedString {
		let s = NSMutableAttributedString(string: self.string.uppercased())
		self.enumerateAttributes(in: NSMakeRange(0, self.length), options: []) { (attr, range, _) in
			s.addAttributes(attr, range: range)
		}
		return s
	}
	
}
