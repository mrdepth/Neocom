//
//  NSAttributedString+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

extension Array where Element: NSAttributedString {

	public func joined(separator: NSAttributedString = NSAttributedString(string: "")) -> NSAttributedString {
		guard !isEmpty else {return NSAttributedString(string: "")}
		let output = NSMutableAttributedString(attributedString: self[0])
		for i in self[1...] {
			output.append(separator)
			output.append(i)
		}
		return output
	}
}

extension NSAttributedString.Key {
	static let fontDescriptorSymbolicTraits = NSAttributedString.Key(rawValue: "UIFontDescriptorSymbolicTraits")
	static let recipientID = NSAttributedString.Key(rawValue: "recipientID")
}

extension NSAttributedString {
	private static let roman = ["0","I","II","III","IV","V"]
	
	convenience init(skillName: String, level: Int) {
		let s = NSMutableAttributedString(string: skillName, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
		let level = level.clamped(to: 0...5)
		if level > 0 {
			s.append(NSAttributedString(string: " \(NSAttributedString.roman[level])", attributes: [NSAttributedString.Key.foregroundColor: UIColor.caption]))
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
					if let traits = value as? UInt32, let fontDescriptor = font.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(rawValue: traits)) {
						let theFont = UIFont(descriptor: fontDescriptor, size: font.pointSize)
						s.addAttribute(NSAttributedString.Key.font, value: theFont, range: range)
						hasFont = true
					}
				case .link:
					if let fontDescriptor = font.fontDescriptor.withSymbolicTraits([.traitBold]) {
						let theFont = UIFont(descriptor: fontDescriptor, size: font.pointSize)
						s.addAttributes([NSAttributedString.Key.font: theFont, NSAttributedString.Key.foregroundColor: UIColor.caption], range: range)
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
				s.addAttribute(NSAttributedString.Key.font, value: font, range: range)
			}
			if (!hasColor) {
				s.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: range)
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
	
	static func + (_ lhs: NSAttributedString, _ rhs: NSAttributedString) -> NSAttributedString {
		let s = lhs.mutableCopy() as! NSMutableAttributedString
		s.append(rhs)
		return s
	}

	static func +<T: StringProtocol> (_ lhs: NSAttributedString, _ rhs: T) -> NSAttributedString {
		let s = lhs.mutableCopy() as! NSMutableAttributedString
		s.append(NSAttributedString(string: String(rhs)))
		return s
	}
	
	static func +<T: StringProtocol> (_ lhs: T, _ rhs: NSAttributedString) -> NSAttributedString {
		let s = NSMutableAttributedString(string: String(lhs))
		s.append(rhs)
		return s
	}

	static func * (_ lhs: NSAttributedString, _ rhs: [NSAttributedString.Key: Any]) -> NSAttributedString {
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

extension StringProtocol {
	static func * (_ lhs: Self, _ rhs: [NSAttributedString.Key: Any]) -> NSAttributedString {
		return NSAttributedString(string: String(lhs), attributes: rhs)
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
			if let link = (attributes[NSAttributedString.Key.link] as? NSURL)?.absoluteString {
				s = "<a href=\"\(link)\">\(s)</a>"
			}
			if let font = attributes[NSAttributedString.Key.font] as? UIFont {
				if font.fontDescriptor.symbolicTraits.contains(UIFontDescriptor.SymbolicTraits.traitBold) {
					s = "<b>\(s)</b>"
				}
			}
			if let color = attributes[NSAttributedString.Key.foregroundColor] as? UIColor {
				s = "<font color=\"\(color.css)ff\">\(s)</font>"
			}
			html.append(s)
		}
		return html
	}
}
