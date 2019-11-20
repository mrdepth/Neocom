//
//  TableViewBackgroundLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class TableViewBackgroundLabel: AccessibilityLabel {
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		numberOfLines = 0
		pointSize = 15
		font = UIFont.systemFont(ofSize: fontSize(contentSizeCategory: UIApplication.shared.preferredContentSizeCategory))
		textColor = UIColor.lightText
	}
	
	convenience init(text: String) {
		self.init(frame: CGRect.zero)
		let paragraph = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
		paragraph.firstLineHeadIndent = 20
		paragraph.headIndent = 20
		paragraph.tailIndent = -20
		paragraph.alignment = NSTextAlignment.center
		attributedText = NSAttributedString(string: text, attributes: [NSAttributedString.Key.paragraphStyle: paragraph])
	}
	
	convenience init(error: Error) {
		self.init(text: error.localizedDescription)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}
