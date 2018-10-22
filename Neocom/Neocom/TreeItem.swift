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
import EVEAPI

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

protocol Routable {
	var route: Routing? {get}
	var secondaryRoute: Routing? {get}
}

extension Routable {
	var secondaryRoute: Routing? { return nil }
}

extension ExpandableItem {
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
	
	class Base<Content: Hashable, Element: TreeItem>: TreeItem, CellConfiguring {
		typealias Child = Element
		var content: Content
		var children: [Child]?
		
		var hashValue: Int {
			return content.hashValue
		}
		
		var diffIdentifier: AnyHashable
		
		init<T: Hashable>(_ content: Content, diffIdentifier: T, children: [Element]? = nil) {
			self.content = content
			self.diffIdentifier = AnyHashable(diffIdentifier)
			self.children = children
		}
		
		init(_ content: Content, children: [Element]? = nil) {
			self.content = content
			self.diffIdentifier = AnyHashable(content)
			self.children = children
		}
		
		func isEqual(_ other: Base<Content, Element>) -> Bool {
			return type(of: self) == type(of: other) && content == other.content
		}
		
		static func == (lhs: Base<Content, Element>, rhs: Base<Content, Element>) -> Bool {
			return lhs.isEqual(rhs)
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
	
	class RoutableRow<Content: Hashable>: Row<Content>, Routable {
		var route: Routing?
		var secondaryRoute: Routing?
		
		init<T: Hashable>(_ content: Content, diffIdentifier: T, route: Routing? = nil, secondaryRoute: Routing? = nil) {
			self.route = route
			self.secondaryRoute = secondaryRoute
			super.init(content, diffIdentifier: diffIdentifier)
		}
		
		init(_ content: Content, route: Routing? = nil, secondaryRoute: Routing? = nil) {
			self.route = route
			self.secondaryRoute = secondaryRoute
			super.init(content)
		}
	}
	
	class ExpandableRow<Content: Hashable, Element: TreeItem>: Base<Content, Element>, ExpandableItem {
		
		var isExpanded: Bool
		var expandIdentifier: CustomStringConvertible?
		
		init<T: Hashable>(_ content: Content, diffIdentifier: T, isExpanded: Bool = true, expandIdentifier: CustomStringConvertible? = nil, children: [Element]? = nil) {
			self.isExpanded = isExpanded
			super.init(content, diffIdentifier: diffIdentifier, children: children)
		}
		
		init(_ content: Content, isExpanded: Bool = true, children: [Element]? = nil) {
			self.isExpanded = isExpanded
			super.init(content, children: children)
		}

	}

}
