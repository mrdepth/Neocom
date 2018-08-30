//
//  TreeHeaderCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class TreeHeaderCell: HeaderCell {
	@IBOutlet var titleLabel: UILabel?
	@IBOutlet var expandIconView: UIImageView?
}

extension Prototype {
	enum TreeHeaderCell {
		static let `default` = Prototype(nib: UINib(nibName: "TreeHeaderCell", bundle: nil), reuseIdentifier: "TreeHeaderCell")
	}
}

extension Tree.Content {
	struct Section: Hashable {
		var prototype: Prototype?
		var title: String?
		var attributedTitle: NSAttributedString?
		var isExpanded: Bool
		
		init (prototype: Prototype = Prototype.TreeHeaderCell.default, title: String? = nil, attributedTitle: NSAttributedString? = nil, isExpanded: Bool = true) {
			self.prototype = prototype
			self.title = title
			self.attributedTitle = attributedTitle
			self.isExpanded = isExpanded
		}
	}
}

extension Tree.Item {
	class Section<T: TreeItem>: Collection<Tree.Content.Section, T>, ExpandableItem {
		weak var treeController: TreeController?
		var isExpanded: Bool {
			get {
				return content.isExpanded
			}
			set {
				content.isExpanded = newValue
				treeController?.reloadRow(for: self, with: .none)
			}
		}
		
		var expandIdentifier: CustomStringConvertible?
		
		init<T: Hashable>(_ content: Tree.Content.Section, diffIdentifier: T, expandIdentifier: CustomStringConvertible?, treeController: TreeController, children: Children? = nil) {
			self.treeController = treeController
			self.expandIdentifier = expandIdentifier
			super.init(content, diffIdentifier: diffIdentifier, children: children)
		}
	}
}

extension Tree.Content.Section: CellConfiguring {
	
	func configure(cell: UITableViewCell) {
		guard let cell = cell as? TreeHeaderCell else {return}
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
		cell.expandIconView?.image = isExpanded ? #imageLiteral(resourceName: "collapse") : #imageLiteral(resourceName: "expand")
	}
	
	
}


