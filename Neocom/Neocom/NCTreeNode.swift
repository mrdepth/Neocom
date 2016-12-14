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
	
	init(cellIdentifier: String, nodeIdentifier: String? = nil, children: [NCTreeNode]? = nil) {
		self.cellIdentifier = cellIdentifier
		self.nodeIdentifier = nodeIdentifier
		self.children = children
	}
	
	func configure(cell: UITableViewCell) {
		
	}
}

class NCTreeSection: NCTreeNode {
	let title: String?
	let attributedTitle: NSAttributedString?
	let configurationHandler: ((UITableViewCell) -> Void)?
	
	init(cellIdentifier: String, nodeIdentifier: String? = nil, title: String, children: [NCTreeNode]? = nil) {
		self.title = title
		self.attributedTitle = nil
		self.configurationHandler = nil
		super.init(cellIdentifier: cellIdentifier, nodeIdentifier: nodeIdentifier, children: children)
	}

	init(cellIdentifier: String, nodeIdentifier: String? = nil, attributedTitle: NSAttributedString?, children: [NCTreeNode]? = nil) {
		self.title = nil
		self.attributedTitle = attributedTitle
		self.configurationHandler = nil
		super.init(cellIdentifier: cellIdentifier, nodeIdentifier: nodeIdentifier, children: children)
	}

	init(cellIdentifier: String, nodeIdentifier: String? = nil, children: [NCTreeNode]? = nil, configurationHandler: ((UITableViewCell) -> Void)? = nil) {
		self.title = nil
		self.attributedTitle = nil
		self.configurationHandler = configurationHandler
		super.init(cellIdentifier: cellIdentifier, nodeIdentifier: nodeIdentifier, children: children)
	}

	override func configure(cell: UITableViewCell) {
		if let title = title, let cell = cell as? NCTableViewHeaderCell {
			cell.titleLabel?.text = title
		}
		else if let attributedTitle = attributedTitle, let cell = cell as? NCTableViewHeaderCell {
			cell.titleLabel?.attributedText = attributedTitle
		}
		else {
			configurationHandler?(cell)
		}
	}
}


class NCTreeRow: NCTreeNode {
	let configurationHandler: ((UITableViewCell) -> Void)?
	
	init(cellIdentifier: String, configurationHandler: ((UITableViewCell) -> Void)? = nil ) {
		self.configurationHandler = configurationHandler
		super.init(cellIdentifier: cellIdentifier, nodeIdentifier: nil, children: nil)
	}
	
	override func configure(cell: UITableViewCell) {
		configurationHandler?(cell)
	}
}
