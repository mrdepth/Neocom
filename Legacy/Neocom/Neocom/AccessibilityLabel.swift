//
//  AccessibilityLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CloudData

class AccessibilityLabel: UILabel {
	var pointSize: CGFloat = 15
	
	override func awakeFromNib() {
		super.awakeFromNib()
		pointSize = font.pointSize
		didChangeContentSizeCategoryObsever = NotificationCenter.default.addNotificationObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: nil, using: { [weak self] (note) in
			self?.didChangeContentSizeCategory(note)
		})
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
	
	private var didChangeContentSizeCategoryObsever: NotificationObserver?
	func didChangeContentSizeCategory(_ note: Notification) {
		font = font.withSize(fontSize(contentSizeCategory: UIApplication.shared.preferredContentSizeCategory))
		invalidateIntrinsicContentSize()
	}
}
