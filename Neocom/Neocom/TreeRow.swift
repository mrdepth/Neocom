//
//  TreeRow.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class TreeRow: TreeNode {
	let segue: String?
	let accessoryButtonSegue: String?
	override var isExpandable: Bool {
		return false
	}
	
	init(cellIdentifier: String?, segue: String? = nil, accessoryButtonSegue: String? = nil) {
		self.segue = segue
		self.accessoryButtonSegue = accessoryButtonSegue
		super.init(cellIdentifier: cellIdentifier)
		self.cellIdentifier = cellIdentifier
	}
}

class TreeSection: TreeNode {
	override var isExpandable: Bool {
		return true
	}
	
	override init(cellIdentifier: String?) {
		super.init(cellIdentifier: cellIdentifier)
	}
}

class DefaultTreeSection: TreeSection {
	let nodeIdentifier: String?
	dynamic var title: String?
	dynamic var attributedTitle: NSAttributedString?

	init(cellIdentifier: String, nodeIdentifier: String? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, children: [TreeNode]? = nil) {
		self.title = title
		self.attributedTitle = attributedTitle
		self.nodeIdentifier = nodeIdentifier
		super.init(cellIdentifier: cellIdentifier)
		self.children = children
	}
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCHeaderTableViewCell {
			cell.object = self
			if title != nil {
				cell.binder.bind("titleLabel.text", toObject: self, withKeyPath: "title", transformer: nil)
			}
			else if attributedTitle != nil {
				cell.binder.bind("titleLabel.attributedText", toObject: self, withKeyPath: "attributedTitle", transformer: nil)
			}
		}
	}
}

class DefaultTreeRow: TreeRow {
	dynamic var image: UIImage?
	dynamic var title: String?
	dynamic var attributedTitle: NSAttributedString?
	dynamic var subtitle: String?
	dynamic var accessoryType: UITableViewCellAccessoryType
	
	init(cellIdentifier: String, image: UIImage? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, subtitle: String? = nil, accessoryType: UITableViewCellAccessoryType = .none, segue: String? = nil, accessoryButtonSegue: String? = nil) {
		self.image = image
		self.title = title
		self.attributedTitle = attributedTitle
		self.subtitle = subtitle
		self.accessoryType = accessoryType

		super.init(cellIdentifier: cellIdentifier, segue: segue, accessoryButtonSegue: accessoryButtonSegue)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.object = self
		cell.iconView?.image = image
		if let attributedTitle = attributedTitle {
			cell.titleLabel?.attributedText = attributedTitle
		}
		else {
			cell.titleLabel?.text = title
		}
		cell.subtitleLabel?.text = subtitle
		cell.accessoryType = accessoryType
	}
}

class NCDefaultFetchedResultsSectionNode<ResultType: NSFetchRequestResult>: FetchedResultsSectionNode<ResultType> {
	
	required init(section: NSFetchedResultsSectionInfo, objectNode: FetchedResultsObjectNode<ResultType>.Type) {
		super.init(section: section, objectNode: objectNode)
		self.cellIdentifier = "NCHeaderTableViewCell"
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.titleLabel?.text = section.name
	}
}
