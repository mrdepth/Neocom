//
//  NavigationItemTitleLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class NavigationItemTitleLabel: UILabel {
	
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
			attributedText = title! + "\n" + subtitle! * [NSAttributedString.Key.font:UIFont.preferredFont(forTextStyle: .footnote), NSAttributedString.Key.foregroundColor: UIColor.lightText]
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
