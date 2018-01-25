//
//  NSAttributedString+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

extension NSAttributedStringKey {
	static let fontDescriptorSymbolicTraits = NSAttributedStringKey(rawValue: "UIFontDescriptorSymbolicTraits")
	static let recipientID = NSAttributedStringKey(rawValue: "recipientID")
}

extension NSAttributedString {
	private static let roman = ["0","I","II","III","IV","V"]
	
	convenience init(skillName: String, level: Int) {
		let s = NSMutableAttributedString(string: skillName, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
		let level = level.clamped(to: 0...5)
		if level > 0 {
			s.append(NSAttributedString(string: " \(NSAttributedString.roman[level])", attributes: [NSAttributedStringKey.foregroundColor: UIColor.caption]))
		}
		self.init(attributedString: s)
	}
	
	func withFont(_ font: UIFont, textColor: UIColor) -> NSAttributedString {
		let s = self.mutableCopy() as! NSMutableAttributedString
		
		self.enumerateAttributes(in: NSMakeRange(0, self.length), options: [], using: {(attr, range, stop) -> Void in
			var hasFont = false
			var hasColor = false
			for (key, value) in attr {
				switch key {
				case .fontDescriptorSymbolicTraits:
					if let traits = value as? UInt32, let fontDescriptor = font.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(rawValue: traits)) {
						let theFont = UIFont(descriptor: fontDescriptor, size: font.pointSize)
						s.addAttribute(NSAttributedStringKey.font, value: theFont, range: range)
						hasFont = true
					}
				case .link:
					if let fontDescriptor = font.fontDescriptor.withSymbolicTraits([.traitBold]) {
						let theFont = UIFont(descriptor: fontDescriptor, size: font.pointSize)
						s.addAttributes([NSAttributedStringKey.font: theFont, NSAttributedStringKey.foregroundColor: UIColor.caption], range: range)
						hasFont = true
						hasColor = true
					}
				case .foregroundColor:
					hasColor = true
				case .font:
					hasFont = true
				default:
					break
				}
			}
			
			if (!hasFont) {
				s.addAttribute(NSAttributedStringKey.font, value: font, range: range)
			}
			if (!hasColor) {
				s.addAttribute(NSAttributedStringKey.foregroundColor, value: textColor, range: range)
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
	
	convenience init(image: UIImage?, font: UIFont?) {
		self.init(attachment: NSTextAttachment(image: image, font: font))
	}
	
	static func +  (_ lhs: NSAttributedString, _ rhs: NSAttributedString) -> NSAttributedString {
		let s = lhs.mutableCopy() as! NSMutableAttributedString
		s.append(rhs)
		return s
	}

	static func +  (_ lhs: NSAttributedString, _ rhs: String) -> NSAttributedString {
		let s = lhs.mutableCopy() as! NSMutableAttributedString
		s.append(NSAttributedString(string: rhs))
		return s
	}
	
	static func +  (_ lhs: String, _ rhs: NSAttributedString) -> NSAttributedString {
		let s = NSMutableAttributedString(string: lhs)
		s.append(rhs)
		return s
	}

	static func * (_ lhs: NSAttributedString, _ rhs: [NSAttributedStringKey: Any]) -> NSAttributedString {
		let s = lhs.mutableCopy() as! NSMutableAttributedString
		let range = NSMakeRange(0, lhs.length)
		s.addAttributes(rhs, range: range)
		return s
	}

}

extension NSMutableAttributedString {
	func appendLine(_ attrString: NSAttributedString) {
		if self.length > 0 {
			self.append(NSAttributedString(string: "\n"))
		}
		self.append(attrString)
	}
}

extension String {
	//subscript(_ attr: [String: Any]) -> NSAttributedString {
	//	return NSAttributedString(string: self, attributes: attr)
	//}
	static func * (_ lhs: String, _ rhs: [NSAttributedStringKey: Any]) -> NSAttributedString {
		return NSAttributedString(string: lhs, attributes: rhs)
	}
}

extension NSTextAttachment {
	
	convenience init(image: UIImage?, font: UIFont?) {
		self.init()
		self.image = image
		if let font = font, let image = image {
			bounds = CGRect(x: 0, y: font.descender, width: image.size.width / image.size.height * font.lineHeight, height: font.lineHeight)
		}
	}
}

extension NSAttributedString {
	var eveHTML: String {
		var html: String = ""
		enumerateAttributes(in: NSMakeRange(0, length), options: []) { (attributes, range, _) in
			var s = attributedSubstring(from: range).string
			s = s.replacingOccurrences(of: "\n", with: "<br>")
			if let link = (attributes[NSAttributedStringKey.link] as? NSURL)?.absoluteString {
				s = "<a href=\"\(link)\">\(s)</a>"
			}
			if let font = attributes[NSAttributedStringKey.font] as? UIFont {
				if font.fontDescriptor.symbolicTraits.contains(UIFontDescriptorSymbolicTraits.traitBold) {
					s = "<b>\(s)</b>"
				}
//				if font.fontDescriptor.symbolicTraits.contains(UIFontDescriptorSymbolicTraits.traitItalic) {
//					s = "<i>\(s)</i>"
//				}
			}
			if let color = attributes[NSAttributedStringKey.foregroundColor] as? UIColor {
				s = "<font color=\"\(color.css)ff\">\(s)</font>"
			}
			html.append(s)
		}
		return html
	}
}
