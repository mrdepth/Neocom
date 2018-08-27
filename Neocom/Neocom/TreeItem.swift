//
//  TreeItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

struct Prototype: Hashable {
	var nib: UINib?
	var reuseIdentifier: String
}

extension UITableView {
	
	func register(_ prototypes: [Prototype]) {
		for prototype in prototypes {
			register(prototype.nib, forCellReuseIdentifier: prototype.reuseIdentifier)
		}
	}
}


extension UICollectionView {
	
	func register(_ prototypes: [Prototype]) {
		for prototype in prototypes {
			register(prototype.nib, forCellWithReuseIdentifier: prototype.reuseIdentifier)
		}
	}
}


protocol CellConfiguring {
	var cellIdentifier: String? {get}
	func configure(cell: UITableViewCell) -> Void
}

protocol ExpandableItem {
	var initiallyExpanded: Bool {get}
	var expandIdentifier: CustomStringConvertible? {get}
}

extension ExpandableItem {
	var initiallyExpanded: Bool {
		return true
	}
	
	var expandIdentifier: CustomStringConvertible? {
		return nil
	}
}

struct TreeVirtualItem<T: TreeItem>: TreeItem {
	typealias Child = T
	var children: [Child]?
	
	init(children: [Child]) {
		self.children = children
	}
}

class TreeContentItem<Content: Hashable, T: TreeItem>: TreeItem {
	typealias Child = T
	typealias Children = [Child]
	
	var content: Content
	var children: Children?

	var hashValue: Int {
		return content.hashValue
	}
	
	var diffIdentifier: AnyHashable
	
	init<T: Hashable>(content: Content, diffIdentifier: T, children: Children? = nil) {
		self.content = content
		self.diffIdentifier = AnyHashable(diffIdentifier)
		self.children = children
	}

	convenience init(content: Content, children: Children? = nil) {
		self.init(content: content, diffIdentifier: content, children: children)
	}

	static func == (lhs: TreeContentItem<Content, Child>, rhs: TreeContentItem<Content, Child>) -> Bool {
		return lhs.content == rhs.content
	}
}

typealias TreeCollectionItem = TreeContentItem

class TreeRowItem<Content: Hashable>: TreeContentItem<Content, TreeItemNull> {
}

extension TreeContentItem: CellConfiguring where Content: CellConfiguring {
	var cellIdentifier: String? {
		return content.cellIdentifier
	}
	
	func configure(cell: UITableViewCell) {
		return content.configure(cell: cell)
	}
}

extension TreeContentItem: ExpandableItem where Content: ExpandableItem {
	var initiallyExpanded: Bool {
		return content.initiallyExpanded
	}
	
	var expandIdentifier: CustomStringConvertible? {
		return content.expandIdentifier
	}
	
}
