//
//  TreeDefaultCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class TreeDefaultCell: RowCell {
	@IBOutlet var titleLabel: UILabel?
	@IBOutlet var subtitleLabel: UILabel?
	@IBOutlet var iconView: UIImageView?
	var accessoryButtonHandler: ActionHandler<UIButton>?
}

extension Prototype {
	enum TreeDefaultCell {
		static let `default` = Prototype(nib: UINib(nibName: "TreeDefaultCell", bundle: nil), reuseIdentifier: "TreeDefaultCell")
		static let attribute = Prototype(nib: UINib(nibName: "TreeDefaultAttributeCell", bundle: nil), reuseIdentifier: "TreeDefaultAttributeCell")
		static let placeholder = Prototype(nib: UINib(nibName: "TreeDefaultPlaceholderCell", bundle: nil), reuseIdentifier: "TreeDefaultPlaceholderCell")
		static let action = Prototype(nib: UINib(nibName: "TreeDefaultActionCell", bundle: nil), reuseIdentifier: "TreeDefaultActionCell")
		static let portrait = Prototype(nib: UINib(nibName: "TreeDefaultPortraitCell", bundle: nil), reuseIdentifier: "TreeDefaultPortraitCell")
		static let contact = Prototype(nib: UINib(nibName: "TreeDefaultContactCell", bundle: nil), reuseIdentifier: "TreeDefaultContactCell")
	}
}

extension Tree.Content {
	enum AccessoryType: Hashable {
		static func == (lhs: Tree.Content.AccessoryType, rhs: Tree.Content.AccessoryType) -> Bool {
			switch (lhs, rhs) {
			case (.none, .none),
				 (.disclosureIndicator, .disclosureIndicator),
				 (.detailDisclosureButton, .detailDisclosureButton),
				 (.checkmark, .checkmark),
				 (.detailButton, .detailButton):
				return true
			case let (.imageButton(l, _), .imageButton(r, _)):
				return l == r
			default:
				return false
			}
		}
		
		case none
		case disclosureIndicator
		case detailDisclosureButton
		case checkmark
		case detailButton
		case imageButton(Image?, (UIControl) -> Void)
		
		func hash(into hasher: inout Hasher) {
			switch self {
			case .none:
				hasher.combine(0)
			case .disclosureIndicator:
				hasher.combine(1)
			case .detailDisclosureButton:
				hasher.combine(2)
			case .checkmark:
				hasher.combine(3)
			case .detailButton:
				hasher.combine(4)
			case let .imageButton(image, _):
				hasher.combine(5)
				hasher.combine(image)
			}
		}
	}
	
	struct Default: Hashable {
		var prototype: Prototype?
		var title: String?
		var attributedTitle: NSAttributedString?
		var subtitle: String?
		var attributedSubtitle: NSAttributedString?
		var image: Image?
		var accessoryType: AccessoryType
		
		init(prototype: Prototype = Prototype.TreeDefaultCell.default,
			 title: String? = nil,
			 attributedTitle: NSAttributedString? = nil,
			 subtitle: String? = nil,
			 attributedSubtitle: NSAttributedString? = nil,
			 image: Image? = nil,
			 accessoryType: AccessoryType = .none) {
			self.prototype = prototype
			self.title = title
			self.subtitle = subtitle
			self.attributedTitle = attributedTitle
			self.attributedSubtitle = attributedSubtitle
			self.image = image
			self.accessoryType = accessoryType
		}
	}
}

extension Tree.Content.Default: CellConfiguring {
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeDefaultCell else {return}
		if let attributedTitle = attributedTitle {
			cell.titleLabel?.attributedText = attributedTitle
			cell.titleLabel?.isHidden = false
		}
		else if let title = title {
			cell.titleLabel?.text = title
			cell.titleLabel?.isHidden = false
		}
		else {
			cell.titleLabel?.text = nil
			cell.titleLabel?.isHidden = true
		}
		
		if let attributedSubtitle = attributedSubtitle {
			cell.subtitleLabel?.attributedText = attributedSubtitle
			cell.subtitleLabel?.isHidden = false
		}
		else if let subtitle = subtitle {
			cell.subtitleLabel?.text = subtitle
			cell.subtitleLabel?.isHidden = false
		}
		else {
			cell.subtitleLabel?.text = nil
			cell.subtitleLabel?.isHidden = true
		}
		
		if let image = image {
			cell.iconView?.image = image.value
			cell.iconView?.isHidden = false
		}
		else {
			cell.iconView?.image = nil
			cell.iconView?.isHidden = true
		}
		
		switch accessoryType {
		case .none:
			cell.accessoryType = .none
		case .disclosureIndicator:
			cell.accessoryType = .disclosureIndicator
		case .detailDisclosureButton:
			cell.accessoryType = .detailDisclosureButton
		case .checkmark:
			cell.accessoryType = .checkmark
		case .detailButton:
			cell.accessoryType = .detailButton
		case let .imageButton(image, handler):
			let button = UIButton(frame: .zero)
			button.setImage(image?.value, for: .normal)
			button.sizeToFit()
			cell.accessoryButtonHandler = ActionHandler(button, for: .touchUpInside, handler: handler)
			cell.accessoryView = button
		}
		
	}
}

