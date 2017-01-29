//: Playground - noun: a place where people can play

import UIKit

public protocol Nodal {
	var children: [Nodal]? {get}
	var descendantCount: Int {get}
}

public protocol Expandable: Nodal {
	//var isExpandable: Bool {get}
	var isExpanded: Bool {get set}
}

public class TreeNode: Expandable, Equatable {
	public var children: [Nodal]? {
		didSet {
			for child in oldValue ?? [] {
				(child as? TreeNode)?.parent = nil
			}
			
			var count = children?.count ?? 0
			
			for child in children ?? [] {
				(child as? TreeNode)?.parent = self
				if let node = child as? Expandable {
					count += node.isExpanded ? node.descendantCount : 0
				}
				else {
					count += child.descendantCount
				}
			}
			descendantCount = count
		}
	}
	
	public static func ==(lhs: TreeNode, rhs: TreeNode) -> Bool {
		return lhs === rhs
	}
	
	public var descendantCount: Int = 0 {
		didSet {
			if isExpanded {
				parent?.descendantCount += descendantCount - oldValue
			}
		}
	}
	
	public var isExpanded: Bool = true {
		didSet {
			if oldValue != isExpanded {
				parent?.descendantCount += isExpanded ? descendantCount : -descendantCount
			}
		}
	}
	
	private(set) weak var parent: TreeNode?
	
	fileprivate var estimatedHeight: CGFloat?
}

public extension Nodal {
	/*var descendantCount: Int {
		var count = children?.count ?? 0
		for child in children ?? [] {
			count += child.descendantCount
		}
		return count
	}*/
	
	func node(at index: Int) -> Nodal? {
		if let node = self as? Expandable, !node.isExpanded {
			return nil
		}
		guard descendantCount >= index else {return nil}
		var i = index
		for child in children ?? [] {
			if i == 0 {
				return child
			}
			else {
				i -= 1
				if let result = child.node(at: i) {
					return result
				}
				else {
					i -= child.descendantCount
				}
			}
		}
		return nil
	}
}

/*public extension Expandable {
	var descendantCount: Int {
		if isExpanded {
			var count = children?.count ?? 0
			for child in children ?? [] {
				count += child.descendantCount
			}
			return count
		}
		else {
			return 0
		}
	}
}*/

let root = TreeNode()
root.children = []
let child1 = TreeNode()
child1.children = []
root.children?.append(child1)
child1.children?.append(TreeNode())
child1.children?.append(TreeNode())
child1.children?.append(TreeNode())

root.node(at: 3)
root.descendantCount
root.children