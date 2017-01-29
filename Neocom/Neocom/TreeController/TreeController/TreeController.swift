//
//  TreeController.swift
//  TreeController
//
//  Created by Artem Shimanski on 28.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

public enum ChangeType : UInt {
	case insert
	case delete
	case move
	case update
}


extension Array where Element: Equatable {
	func transition(to: Array<Element>, handler: (_ oldIndex: Int?, _ newIndex: Int?, _ changeType: ChangeType) -> Void) {
		let from = self
		var arr = from
		
		for i in (0..<from.count).reversed() {
			if to.index(of: from[i]) == nil {
				handler(i, nil, .delete)
				arr.remove(at: i)
			}
		}
		
		for i in 0..<to.count {
			let obj = to[i]
			if let j = arr.index(of: obj) {
				if j != i {
					handler(from.index(of: obj), i, .move)
				}
				else {
					handler(from.index(of: obj), i, .update)
				}
			}
			else {
				handler(nil, i, .insert)
			}
		}
	}
	
	mutating func remove(at: IndexSet) {
		for i in at.reversed() {
			self.remove(at: i)
		}
	}
}

public protocol Nodal {
	var children: [Nodal]? {get}
}

public protocol Expandable: Nodal {
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
	
	var descendantCount: Int = 0 {
		didSet {
			if isExpanded {
				parent?.descendantCount += oldValue - descendantCount
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
	
	fileprivate weak var treeController: TreeController?
	fileprivate var estimatedHeight: CGFloat?
}

public extension Nodal {
	var descendantCount: Int {
		var count = children?.count ?? 0
		for child in children ?? [] {
			count += child.descendantCount
		}
		return count
	}
	
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

public extension Expandable {
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
}

@objc protocol TreeControllerDelegate: NSObjectProtocol {
	func treeController(_ treeController: NCTreeController, cellIdentifierForItem item: AnyObject) -> String
	
	@objc optional func treeController(_ treeController: NCTreeController, child:Int, ofItem item: AnyObject?) -> AnyObject
	@objc optional func treeController(_ treeController: NCTreeController, numberOfChildrenOfItem item: AnyObject?) -> Int
	@objc optional func treeController(_ treeController: NCTreeController, configureCell cell: UITableViewCell, withItem item: AnyObject) -> Void
	@objc optional func treeController(_ treeController: NCTreeController, isItemExpandable item: AnyObject) -> Bool
	@objc optional func treeController(_ treeController: NCTreeController, isItemExpanded item: AnyObject) -> Bool
	@objc optional func treeController(_ treeController: NCTreeController, estimatedHeightForRowWithItem item: AnyObject) -> CGFloat
	@objc optional func treeController(_ treeController: NCTreeController, heightForRowWithItem item: AnyObject) -> CGFloat
	@objc optional func treeController(_ treeController: NCTreeController, didExpandCell cell: UITableViewCell, withItem item: AnyObject) -> Void
	@objc optional func treeController(_ treeController: NCTreeController, didCollapseCell cell: UITableViewCell, withItem item: AnyObject) -> Void
	@objc optional func treeController(_ treeController: NCTreeController, didSelectCell cell: UITableViewCell, withItem item: AnyObject) -> Void
	@objc optional func treeController(_ treeController: NCTreeController, canEditChild child:Int, ofItem item: AnyObject?) -> Bool
	@objc optional func treeController(_ treeController: NCTreeController, editingStyleForChild child: Int, ofItem item: AnyObject?) -> UITableViewCellEditingStyle
	@objc optional func treeController(_ treeController: NCTreeController, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forChild child: Int, ofItem item: AnyObject?) -> Void
	@objc optional func treeController(_ treeController: NCTreeController, editActionsForChild child: Int, ofItem item: AnyObject?) -> [UITableViewRowAction]?
}

public class TreeController: NSObject, UITableViewDelegate, UITableViewDataSource {
	var rootNode: Nodal?
	
	//MARK: - UITableViewDataSource
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return rootNode?.descendantCount ?? 0
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return tableView.dequeueReusableCell(withIdentifier: "Cell")!
	}
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return nil
	}
	
	public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return nil
	}
	
	public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
		return nil
	}
	
	public func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
		return 0
	}
	
	public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
	}
	
	public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		
	}
	
	//MARK: - UITableViewDelegate
	
}
