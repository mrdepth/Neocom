//
//  NCTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCTableViewCell: UITableViewCell {
	var object: Any?
	lazy var binder: NCBinder = {
		return NCBinder(target: self)
	}()
	
	override func prepareForReuse() {
		binder.unbindAll()
		super.prepareForReuse()
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.selectedBackgroundView = UIView(frame: self.bounds)
		self.selectedBackgroundView?.backgroundColor = UIColor.separatorColor
	}
}

class NCTableViewDefaultCell: NCTableViewCell {
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var subtitleLabel: UILabel?
}
