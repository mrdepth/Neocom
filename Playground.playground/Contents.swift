//: Playground - noun: a place where people can play

import UIKit
let url = Bundle.main.url(forResource: "mail", withExtension: "html")!
let data = try! Data(contentsOf: url)


let s = try! NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)

extension NSAttributedString {
	var eveHTML: String {
		var html: String = ""
		enumerateAttributes(in: NSMakeRange(0, length), options: []) { (attributes, range, _) in
			var s = attributedSubstring(from: range).string
			if let link = (attributes[NSLinkAttributeName] as? NSURL)?.absoluteString {
				s = "<a href=\"\(link)\">\(s)</a>"
			}
			if let font = attributes[NSFontAttributeName] as? UIFont {
				if font.fontDescriptor.symbolicTraits.contains(UIFontDescriptorSymbolicTraits.traitBold) {
					s = "<b>\(s)</b>"
				}
				if font.fontDescriptor.symbolicTraits.contains(UIFontDescriptorSymbolicTraits.traitItalic) {
					s = "<i>\(s)</i>"
				}
			}
			html.append(s)
		}
		return html
	}
}

s.eveHTML