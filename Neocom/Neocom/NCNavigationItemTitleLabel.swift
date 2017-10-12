//
//  NCNavigationItemTitleLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.10.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

class NCNavigationItemTitleLabel: UILabel {
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		numberOfLines = 2
		textAlignment = .center
		textColor = .white
		minimumScaleFactor = 0.5
		font = UIFont.systemFont(ofSize: 17)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func set(title: String?, subtitle: String?) {
		switch (title?.isEmpty ?? true, subtitle?.isEmpty ?? true) {
		case (false, false):
			attributedText = title! + "\n" + subtitle! * [NSAttributedStringKey.font:UIFont.preferredFont(forTextStyle: .footnote), NSAttributedStringKey.foregroundColor: UIColor.lightText]
		case (false, true):
			attributedText = title! * [:]
		case (true, false):
			attributedText = subtitle! * [:]
		default:
			attributedText = nil
		}
		sizeToFit()
	}
}
