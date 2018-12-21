//
//  TreeHeaderCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class TreeHeaderCell: HeaderCell {
	@IBOutlet var titleLabel: UILabel?
	@IBOutlet var iconView: UIImageView?
}

extension Prototype {
	enum TreeHeaderCell {
		static let `default` = Prototype(nib: UINib(nibName: "TreeHeaderCell", bundle: nil), reuseIdentifier: "TreeHeaderCell")
	}
}


extension Tree.Content {
	struct Header: Hashable {
		var prototype: Prototype?
		var title: String?
		var attributedTitle: NSAttributedString?
		var image: Image?
		
		init (prototype: Prototype = Prototype.TreeHeaderCell.default, title: String? = nil, attributedTitle: NSAttributedString? = nil, image: Image? = nil) {
			self.prototype = prototype
			self.title = title
			self.attributedTitle = attributedTitle
			self.image = image
		}
	}
}

extension Tree.Item {
	class Header<Element: TreeItem>: Collection<Tree.Content.Header, Element> {
	}
}

extension Tree.Content.Header: CellConfigurable {
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
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
		cell.iconView?.image = image?.value
		cell.iconView?.isHidden = image == nil
	}
}

