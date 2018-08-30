//
//  TreeItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

struct Prototype: Hashable {
	var nib: UINib?
	var reuseIdentifier: String
}

extension TreeItem {
	var asAnyItem: AnyTreeItem {
		return AnyTreeItem(self)
	}
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
	var prototype: Prototype? {get}
	func configure(cell: UITableViewCell) -> Void
}

protocol ExpandableItem {
	var isExpanded: Bool {get set}
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

enum Tree {
	enum Item {
		
	}
	enum Content {
		
	}
}

extension Tree.Item {
	struct Virtual<T: TreeItem>: TreeItem {
		typealias Child = T
		var children: [Child]?
		
		init(children: [Child]) {
			self.children = children
		}
	}
	
	class Base<Content: Hashable, T: TreeItem>: TreeItem, CellConfiguring {
		typealias Child = T
		typealias Children = [Child]
		
		var content: Content
		var children: Children?
		
		var hashValue: Int {
			return content.hashValue
		}
		
		var diffIdentifier: AnyHashable
		
		init<T: Hashable>(_ content: Content, diffIdentifier: T, children: Children? = nil) {
			self.content = content
			self.diffIdentifier = AnyHashable(diffIdentifier)
			self.children = children
		}
		
		init(_ content: Content, children: Children? = nil) {
			self.content = content
			self.diffIdentifier = AnyHashable(content)
			self.children = children
		}
		
		static func == (lhs: Base<Content, Child>, rhs: Base<Content, Child>) -> Bool {
			return lhs.content == rhs.content
		}
		
		var prototype: Prototype? {
			return (content as? CellConfiguring)?.prototype
		}
		
		func configure(cell: UITableViewCell) {
			(content as? CellConfiguring)?.configure(cell: cell)
		}

	}
	

	typealias Collection = Base

	class Row<Content: Hashable>: Base<Content, TreeItemNull> {
		init<T: Hashable>(_ content: Content, diffIdentifier: T) {
			super.init(content, diffIdentifier: diffIdentifier)
		}
		
		init(_ content: Content) {
			super.init(content)
		}
	}

	class APIResultRow<Content: Hashable>: Row<Content> {
		let value: Future<APIResult<Content>>
		weak var treeController: TreeController?
		
		init<T: Hashable>(_ content: Content, value: Future<APIResult<Content>>, diffIdentifier: T, treeController: TreeController) {
			self.value = value
			self.treeController = treeController
			super.init(content, diffIdentifier: diffIdentifier)

			value.then(on: .main) { [weak self] value -> Void in
				self?.didUpdate(value.value)
			}
		}
		
		func didUpdate(_ content: Content) {
			self.content = content
			treeController?.reloadRow(for: self, with: .fade)
		}
		
		func didFail(_ error: Error) {
			
		}
	}
}
