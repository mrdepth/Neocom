//
//  File.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCTableViewBackgroundLabel: NCLabel {
	
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
		attributedText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.paragraphStyle: paragraph])
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
}
