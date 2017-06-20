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
//        backgroundView = UIView(frame: bounds)
//        backgroundView?.backgroundColor = UIColor.cellBackground
		selectedBackgroundView = UIView(frame: bounds)
		selectedBackgroundView?.backgroundColor = UIColor.separator
		tintColor = .caption
	}
    
}

class NCDefaultTableViewCell: NCTableViewCell {
	
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var subtitleLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        indentationWidth = 32
    }
	
	var indentationConstraint: NSLayoutConstraint? {
		get {
			guard let stackView = self.iconView?.superview else {return nil}
			return stackView.superview?.constraints.first {
				return $0.firstItem === stackView && $0.secondItem === stackView.superview && $0.firstAttribute == .leading && $0.secondAttribute == .leading
			}
		}
	}
	
	override var indentationWidth: CGFloat {
		didSet {
			updateIndent()
		}
	}
	
	override var indentationLevel: Int {
		didSet {
			updateIndent()
		}
	}
	
	private func updateIndent() {
		let level = max(0, indentationLevel - 1)
		let indent = 15 + CGFloat(level) * indentationWidth
		self.indentationConstraint?.constant = indent
		self.separatorInset.left = indent
	}
	

}

class NCActionTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel?
	
}

extension Prototype {
	enum NCDefaultTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCDefaultTableViewCell", bundle: nil), reuseIdentifier: "NCDefaultTableViewCell")
		static let compact = Prototype(nib: UINib(nibName: "NCDefaultCompactTableViewCell", bundle: nil), reuseIdentifier: "NCDefaultCompactTableViewCell")
		static let placeholder = Prototype(nib: UINib(nibName: "NCPlaceholderTableViewCell", bundle: nil), reuseIdentifier: "NCPlaceholderTableViewCell")
		static let image = Prototype(nib: nil, reuseIdentifier: "NCImageTableViewCell")
		static let noImage = Prototype(nib: UINib(nibName: "NCDefaultNoImageTableViewCell", bundle: nil), reuseIdentifier: "NCDefaultNoImageTableViewCell")
		static let attribute = Prototype(nib: UINib(nibName: "NCAttributeTableViewCell", bundle: nil), reuseIdentifier: "NCAttributeTableViewCell")
		
	}
	
	enum NCActionTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCActionTableViewCell", bundle: nil), reuseIdentifier: "NCActionTableViewCell")
	}

}
