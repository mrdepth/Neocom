//
//  NCTreeNode.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

class NCTreeNode: NSObject {
	dynamic var children: [NCTreeNode]?
	let cellIdentifier: String
	let nodeIdentifier: String?
	var canExpand: Bool {get {return self.children?.count ?? 0 > 0}}
	var expanded: Bool = true
	var object: Any?
	
	init(cellIdentifier: String, nodeIdentifier: String? = nil, children: [NCTreeNode]? = nil, object: Any? = nil) {
		self.cellIdentifier = cellIdentifier
		self.nodeIdentifier = nodeIdentifier
		self.children = children
		self.object = object
	}
	
	func configure(cell: UITableViewCell) {
		
	}
}

class NCTreeSection: NCTreeNode {
	dynamic var title: String?
	dynamic var attributedTitle: NSAttributedString?
	var configurationHandler: ((UITableViewCell) -> Void)?
	
	init(cellIdentifier: String, nodeIdentifier: String? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, children: [NCTreeNode]? = nil, object: Any? = nil, configurationHandler: ((UITableViewCell) -> Void)? = nil) {
		self.title = title
		self.attributedTitle = attributedTitle
		self.configurationHandler = configurationHandler
		super.init(cellIdentifier: cellIdentifier, nodeIdentifier: nodeIdentifier, children: children, object: object)
	}

	override func configure(cell: UITableViewCell) {
		if let configurationHandler = configurationHandler {
			configurationHandler(cell)
		}
		else if let cell = cell as? NCHeaderTableViewCell {
			cell.object = object
			if title != nil {
				//cell.titleLabel?.text = title
				cell.binder.bind("titleLabel.text", toObject: self, withKeyPath: "title", transformer: nil)
			}
			else if attributedTitle != nil {
				//cell.titleLabel?.attributedText = attributedTitle
				cell.binder.bind("titleLabel.attributedText", toObject: self, withKeyPath: "attributedTitle", transformer: nil)
			}

		}
	}
}


class NCTreeRow: NCTreeNode {
	let configurationHandler: ((UITableViewCell) -> Void)?
	
	init(cellIdentifier: String, object: Any? = nil, children: [NCTreeNode]? = nil, configurationHandler: ((UITableViewCell) -> Void)? = nil ) {
		self.configurationHandler = configurationHandler
		super.init(cellIdentifier: cellIdentifier, nodeIdentifier: nil, children: children, object: object)
	}
	
	override func configure(cell: UITableViewCell) {
		configurationHandler?(cell)
	}
}

class NCDefaultTreeRow: NCTreeRow {
	dynamic var image: UIImage?
	dynamic var title: String?
	dynamic var attributedTitle: NSAttributedString?
	dynamic var subtitle: String?
	var segue: String?
	dynamic var accessoryType: UITableViewCellAccessoryType
	
	init(cellIdentifier: String, image: UIImage? = nil, title: String? = nil, attributedTitle: NSAttributedString? = nil, subtitle: String? = nil, accessoryType: UITableViewCellAccessoryType = .none, segue: String? = nil, object: Any? = nil, children: [NCTreeNode]? = nil) {
		self.image = image
		self.title = title
		self.attributedTitle = attributedTitle
		self.subtitle = subtitle
		self.segue = segue
		self.accessoryType = accessoryType
		super.init(cellIdentifier: cellIdentifier, object: object, children: children, configurationHandler: nil)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
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
