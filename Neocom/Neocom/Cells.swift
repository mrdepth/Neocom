//
//  Cells.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class RowCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
		selectedBackgroundView = UIView(frame: bounds)
		selectedBackgroundView?.backgroundColor = UIColor.separator
		tintColor = .caption

//		backgroundColor = .cellBackground
//		tintColor = .caption
	}
}

class HeaderCell: UITableViewCell {
	override func awakeFromNib() {
		super.awakeFromNib()
//		backgroundColor = .background
	}
}
