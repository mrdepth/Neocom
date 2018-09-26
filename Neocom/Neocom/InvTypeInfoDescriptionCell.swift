//
//  InvTypeInfoDescriptionCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class InvTypeInfoDescriptionCell: HeaderCell {
	@IBOutlet var titleLabel: UILabel?
	@IBOutlet var subtitleLabel: UILabel?
	@IBOutlet var iconView: UIImageView?
	@IBOutlet var descriptionTextView: UITextView?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		descriptionTextView?.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.caption]
		descriptionTextView?.textContainerInset = .zero
		descriptionTextView?.textContainer.lineFragmentPadding = 0
		descriptionTextView?.layoutManager.usesFontLeading = false
	}
}

extension Prototype {
	enum InvTypeInfoDescriptionCell {
		static let `default` = Prototype(nib: UINib(nibName: "InvTypeInfoDescriptionCell", bundle: nil), reuseIdentifier: "InvTypeInfoDescriptionCell")
		static let compact = Prototype(nib: UINib(nibName: "InvTypeInfoDescriptionCompactCell", bundle: nil), reuseIdentifier: "InvTypeInfoDescriptionCompactCell")
	}
}


extension Tree.Content {
	struct InvTypeInfoDescription: Hashable {
		var prototype: Prototype?
		var title: String
		var subtitle: String?
		var image: UIImage?
		var typeDescription: NSAttributedString?
	}
}

extension Tree.Content.InvTypeInfoDescription: CellConfiguring {
	func configure(cell: UITableViewCell) {
		guard let cell = cell as? InvTypeInfoDescriptionCell else {return}
		cell.titleLabel?.text = title
		cell.subtitleLabel?.text = subtitle
		cell.iconView?.image = image
		
		cell.descriptionTextView?.attributedText = typeDescription?.withFont(cell.descriptionTextView!.font!, textColor: cell.descriptionTextView!.textColor!)
	}
}
