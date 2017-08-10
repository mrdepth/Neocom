//
//  NCLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCLabel: UILabel {
	var pointSize: CGFloat = 15
	
	override func awakeFromNib() {
		super.awakeFromNib()
		pointSize = font.pointSize
		NotificationCenter.default.addObserver(self, selector: #selector(didChangeContentSizeCategory(_:)), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
	}
	
	func fontSize(contentSizeCategory: UIContentSizeCategory) -> CGFloat {
		var p = pointSize
		switch contentSizeCategory {
		case UIContentSizeCategory.extraSmall:
			p -= 2
		case UIContentSizeCategory.small:
			p -= 1
		case UIContentSizeCategory.large:
			p += 1
		case UIContentSizeCategory.extraLarge:
			p += 3
		case UIContentSizeCategory.extraExtraLarge:
			p += 5
		case UIContentSizeCategory.extraExtraExtraLarge:
			p += 5
		case UIContentSizeCategory.accessibilityMedium,
		     UIContentSizeCategory.accessibilityLarge,
			UIContentSizeCategory.accessibilityExtraLarge,
			UIContentSizeCategory.accessibilityExtraExtraLarge,
			UIContentSizeCategory.accessibilityExtraExtraExtraLarge:
			p += 5
		default:
			break
		}
		
		return max(p, 11)
	}
	
	func didChangeContentSizeCategory(_ note: NSNotification) {
		font = font.withSize(fontSize(contentSizeCategory: UIApplication.shared.preferredContentSizeCategory))
		invalidateIntrinsicContentSize()
	}
}
