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
	private(set) lazy var binder: NCBinder = {
		return NCBinder(target: self)
	}()
	
	override func prepareForReuse() {
		binder.unbindAll()
		super.prepareForReuse()
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.selectedBackgroundView = UIView(frame: self.bounds)
		self.selectedBackgroundView?.backgroundColor = UIColor.separator
		tintColor = .caption
	}
}

class NCDefaultTableViewCell: NCTableViewCell {
	
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var subtitleLabel: UILabel?
	
	var indentationConstraint: NSLayoutConstraint? {
		get {
			guard let iconView = self.iconView else {return nil}
			return iconView.superview?.constraints.first {
				return $0.firstItem === iconView && $0.secondItem === iconView.superview && $0.firstAttribute == .leading && $0.secondAttribute == .leading
			}
		}
	}
	
	override var indentationLevel: Int {
		didSet {
			let level = max(0, indentationLevel - 1)
			self.indentationConstraint?.constant = CGFloat(15 + level * 10)
		}
	}
}

class NCActionTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel?
	
}

extension Prototype {
	enum NCDefaultTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCDefaultTableViewCell", bundle: nil), reuseIdentifier: "NCDefaultTableViewCell")
		static let compact = Prototype(nib: UINib(nibName: "NCDefaultCompactTableViewCell", bundle: nil), reuseIdentifier: "NCDefaultCompactTableViewCell")
	}
	
	enum NCActionTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCActionTableViewCell", bundle: nil), reuseIdentifier: "NCActionTableViewCell")
	}

}
