//
//  NCTreeController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCTreeControllerNode: NSObject {
	unowned let treeController: NCTreeController
	let childrenKeyPath: String?
	weak var parent: NCTreeControllerNode?
	var index: Int = 0
	var indentationLevel: Int = 0
	var estimatedHeight: CGFloat = 0
	
	init(treeController: NCTreeController, parent: NCTreeControllerNode?) {
		self.treeController = treeController
		self.childrenKeyPath = treeController.childrenKeyPath
		self.parent = parent
	}
	
	lazy var item: AnyObject? = {
		var v: AnyObject
		if let parent = self.parent {
			if let childrenKeyPath = self.childrenKeyPath {
				var item: AnyObject = (parent.item?.value(forKeyPath: childrenKeyPath) as? [AnyObject])?[self.index] ??
					self.treeController.content![self.index]
				item.addObserver(self, forKeyPath: childrenKeyPath, options: [], context: nil)
				return item
			}
			else {
				return self.treeController.delegate!.treeController!(self.treeController, child: self.index, ofItem: parent.item)
			}
		}
		return nil
	}()
	
	deinit {
		if let item = self.item, let childrenKeyPath = self.childrenKeyPath {
			item.removeObserver(self, forKeyPath: childrenKeyPath)
		}
	}
	
	lazy var children: [NCTreeControllerNode] = {
		var array = [NCTreeControllerNode]()
		
		let n: Int
		if let childrenKeyPath = self.childrenKeyPath {
			if let item = self.item {
				if let array = item.value(forKeyPath: childrenKeyPath) as? [Any] {
					n = array.count
				}
				else {
					n = 0
				}
			}
			else {
				n = self.treeController.content?.count ?? 0
			}
		}
		else {
			n = self.treeController.delegate!.treeController!(self.treeController, numberOfChildrenOfItem: self.item)
		}
		
		for i in 0..<n {
			let node = NCTreeControllerNode(treeController: self.treeController, parent: self)
			node.index = i
			node.indentationLevel = self.indentationLevel + 1
			array.append(node)
		}
		
		return array
	}()
	
	lazy var expandable: Bool = {
		if let item = self.item {
			if let expandable = self.treeController.delegate?.treeController?(self.treeController, isItemExpandable: item) {
				return expandable
			}
			else {
				return self.children.count > 0
			}
		}
		return false
	}()
	
	lazy var expanded: Bool = {
		if let item = self.item {
			if let expanded = self.treeController.delegate?.treeController?(self.treeController, isItemExpanded: item) {
				return expanded
			}
		}
		return true
	}()
	
	func insertChildren(_ children: IndexSet) -> Void {
		var array = self.children
		for i in children {
			let node = NCTreeControllerNode(treeController: self.treeController, parent: self)
			node.index = i
			node.indentationLevel = self.indentationLevel + 1
			array.insert(node, at: i)
		}
		var index = 0
		for child in array {
			child.index = index
			index += 1
		}
		self.children = array
	}
	
	func removeChildren(_ children: IndexSet) -> Void {
		var array = self.children
		for i in children.reversed() {
			array.remove(at: i)
		}
		var index = 0
		for child in array {
			child.index = index
			index += 1
		}
		self.children = array
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if let childrenKeyPath = self.childrenKeyPath,
			let item = self.item,
			let object = object as AnyObject?,
			object === item && childrenKeyPath == keyPath {
			if let n = change?[.kindKey] as? NSNumber, let kind = NSKeyValueChange(rawValue: n.uintValue) {
				let indexes = change?[.indexesKey] as? IndexSet
				switch kind {
				case .setting:
					let array = item.value(forKeyPath: childrenKeyPath) as? [Any]
					treeController.deleteChildren(IndexSet(integersIn: 0..<children.count), ofNode: self, withRowAnimation: .bottom)
					treeController.insertChildren(IndexSet(integersIn: 0..<(array?.count ?? 0)), ofNode: self, withRowAnimation: .bottom)
				case .insertion:
					if let indexes = indexes {
						treeController.insertChildren(indexes, ofNode: self, withRowAnimation: .bottom)
					}
				case .removal:
					if let indexes = indexes {
						treeController.deleteChildren(indexes, ofNode: self, withRowAnimation: .bottom)
					}
				case .replacement:
					if let indexes = indexes {
						treeController.reloadChildren(indexes, ofNode: self, withRowAnimation: .fade)
					}
				}
			}
		}
	}
}

@objc protocol NCTreeControllerDelegate: NSObjectProtocol {
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

@objc protocol NCExpandable {
	func setExpanded(_ expanded: Bool, animated: Bool) -> Void
}

class NCTreeController: NSObject, UITableViewDataSource, UITableViewDelegate {
	
	var childrenKeyPath: String?
	@objc dynamic var content: [NSObject]?/* {
		didSet {
			if let root = _root, let oldValue = oldValue, let content = content {
				self.tableView?.beginUpdates()
				oldValue.transition(to: content, handler: { (old, new, type) in
					switch type {
					case .insert:
						insertChildren(IndexSet(integer: new!), ofNode: root, withRowAnimation: .bottom)
					case .delete:
						deleteChildren(IndexSet(integer: old!), ofNode: root, withRowAnimation: .bottom)
					case .move:
						deleteChildren(IndexSet(integer: old!), ofNode: root, withRowAnimation: .fade)
						insertChildren(IndexSet(integer: new!), ofNode: root, withRowAnimation: .fade)
					case .update:
						reloadChildren(IndexSet(integer: new!), ofNode: root, withRowAnimation: .fade)
					}
				})
				self.tableView?.endUpdates()
			}
		}
	}*/
	@IBOutlet weak var delegate: NCTreeControllerDelegate?
	@IBOutlet weak var tableView: UITableView?
	
	
	func reloadRows(items: [AnyObject], rowAnimation animation: UITableViewRowAnimation) {
		var indexPaths = [IndexPath]()
		for item in items {
			if let indexPath = indexPath(item: item) {
				indexPaths.append(indexPath)
			}
		}
		if indexPaths.count > 0 {
			self.tableView?.reloadRows(at: indexPaths, with: animation)
		}
	}

	func insertChildren(_ children: IndexSet, ofItem item: AnyObject?,  withRowAnimation animation: UITableViewRowAnimation) {
		let node = self.node(item: item)!

		assert(self.content == nil && self.delegate!.treeController!(self, numberOfChildrenOfItem: item) == node.children.count + children.count)
		insertChildren(children, ofNode: node, withRowAnimation: animation)
	}

	func deleteChildren(_ children: IndexSet, ofItem item: AnyObject?,  withRowAnimation animation: UITableViewRowAnimation) {
		let node = self.node(item: item)!
		
		assert(self.content == nil && self.delegate!.treeController!(self, numberOfChildrenOfItem: item) == node.children.count - children.count)
		deleteChildren(children, ofNode: node, withRowAnimation: animation)
	}
	
	func deselectItem(_ item: AnyObject, animated: Bool) {
		guard let indexPath = indexPath(item: item) else {return}
		tableView?.deselectRow(at: indexPath, animated: animated)
	}

	
	func itemExpanded(_ item: AnyObject) -> Bool {
		return node(item: item)!.expanded
	}
	
	func reloadData() {
		_root = nil
		_numberOfRows = nil
		self.tableView?.reloadData()
	}
	
	func parentItem(forItem item: AnyObject) -> AnyObject? {
		return self.node(item: item)!.parent?.item
	}
	
	func item(forIndexPath indexPath: IndexPath) -> AnyObject? {
		let node = self.node(indexPath: indexPath)!
		return node.item
	}
	
	override func responds(to aSelector: Selector!) -> Bool {
		if aSelector == #selector(tableView(_:canEditRowAt:)) || aSelector == #selector(tableView(_:editingStyleForRowAt:)) {
			return self.delegate?.responds(to: aSelector) == true
		}
		else {
			return super.responds(to: aSelector)
		}
	}

	//MARK: UITableViewDataSource
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.numberOfRows
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let node = self.node(indexPath: indexPath)!
		let cell = tableView.dequeueReusableCell(withIdentifier: self.delegate!.treeController(self, cellIdentifierForItem: node.item!), for: indexPath)
		cell.indentationLevel = node.indentationLevel
		
		self.delegate?.treeController?(self, configureCell: cell, withItem: node.item!)
		
		if let cell = cell as? NCExpandable {
			cell.setExpanded(node.expanded, animated: false)
		}
		return cell;
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		if let node = self.node(indexPath: indexPath) {
			return self.delegate?.treeController?(self, canEditChild: node.index, ofItem: node.parent?.item) ?? false
		}
		else {
			return false
		}
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if let node = self.node(indexPath: indexPath) {
			self.delegate?.treeController?(self, commitEditingStyle: editingStyle, forChild: node.index, ofItem: node.parent?.item)
		}
	}
	
	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		if let node = self.node(indexPath: indexPath) {
			return self.delegate?.treeController?(self, editActionsForChild: node.index, ofItem: node.parent?.item)
		}
		else {
			return nil
		}
	}
	
	//MARK: UITableViewDelegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let node = self.node(indexPath: indexPath), let cell = tableView.cellForRow(at: indexPath) {
			if node.children.count > 0 && node.expandable {
				var row = indexPath.row
				var indexPaths = [IndexPath]()
				
				func enumerate(_ node: NCTreeControllerNode) {
					for child in node.children {
						row += 1
						indexPaths.append(IndexPath(row: row, section: 0))
						if child.expanded {
							enumerate(child)
						}
					}
				}
				
				enumerate(node)
				node.expanded = !node.expanded;
				
				if let cell = cell as? NCExpandable {
					cell.setExpanded(node.expanded, animated: true)
				}
				
				if node.expanded {
					_numberOfRows! += indexPaths.count
					tableView.insertRows(at: indexPaths, with: .fade)
					self.delegate?.treeController?(self, didExpandCell: cell, withItem: node.item!)
				}
				else {
					_numberOfRows! -= indexPaths.count
					tableView.deleteRows(at: indexPaths, with: .fade)
					self.delegate?.treeController?(self, didCollapseCell: cell, withItem: node.item!)
				}
			}
			self.delegate?.treeController?(self, didSelectCell: cell, withItem: node.item!)
		}
	}
	
	func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		if let node = self.node(indexPath: indexPath) {
			if let height = self.delegate?.treeController?(self, estimatedHeightForRowWithItem: node.item!) {
				return height
			}
			else if node.estimatedHeight > 0 {
				return node.estimatedHeight
			}
			else {
				return tableView.estimatedRowHeight > 0 ? tableView.estimatedRowHeight : UITableViewAutomaticDimension
			}
		}
		else {
			return UITableViewAutomaticDimension
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if let node = self.node(indexPath: indexPath) {
			if let height = self.delegate?.treeController?(self, heightForRowWithItem: node.item!) {
				return height
			}
		}
		if tableView.estimatedRowHeight > 0 || (self.delegate?.responds(to: #selector(NCTreeControllerDelegate.treeController(_:estimatedHeightForRowWithItem:))) ?? false) {
			return UITableViewAutomaticDimension
		}
		else {
			return tableView.rowHeight
		}
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		if let node = self.node(indexPath: indexPath) {
			if let editingStyle = self.delegate?.treeController?(self, editingStyleForChild: node.index, ofItem: node.parent?.item) {
				return editingStyle
			}
		}
		return .none
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if let node = self.node(indexPath: indexPath) {
			node.estimatedHeight = cell.bounds.size.height
		}
	}
	
	//MARK: Private
	
	private var _root: NCTreeControllerNode?
	private var root: NCTreeControllerNode {
		get {
			if let root = _root {
				return root
			}
			else {
				let root = NCTreeControllerNode(treeController: self, parent: nil)
				root.indentationLevel = -1
				root.expanded = true
				_root = root
				return root
			}
		}
	}
	
	private var _numberOfRows: Int?
	private var numberOfRows: Int {
		get {
			if let numberOfRows = _numberOfRows {
				return numberOfRows
			}
			else {
				let numberOfRows = self.numberOfRows(node: self.root)
				_numberOfRows = numberOfRows
				return numberOfRows
			}
		}
	}
	
	private func numberOfRows(node: NCTreeControllerNode) -> Int {
		var numberOfRows = 0
		func enumerate(_ node: NCTreeControllerNode) -> Void {
			if node.expanded {
				numberOfRows += node.children.count
				for child in node.children {
					enumerate(child)
				}
			}
		}
		enumerate(node)
		return numberOfRows
	}
	
	private func node(indexPath: IndexPath) -> NCTreeControllerNode? {
		var row = indexPath.row
		func enumerate(_ node: NCTreeControllerNode) -> NCTreeControllerNode? {
			if node.expanded {
				for child in node.children {
					if row == 0 {
						return child
					}
					row -= 1
					if let node = enumerate(child) {
						return node
					}
				}
			}
			return nil
		}
		
		return enumerate(self.root)
	}
	
	private func node(item: AnyObject?) -> NCTreeControllerNode? {
		if let item = item {
			func enumerate(_ node: NCTreeControllerNode) -> NCTreeControllerNode? {
				for child in node.children {
					if let childItem = child.item as? AnyHashable, let item = item as? AnyHashable, childItem == item {
						return child
					}
					else if let childItem = child.item, childItem === item {
						return child
					}
					if let node = enumerate(child) {
						return node
					}
				}
				return nil
			}
			return enumerate(self.root)
		}
		else {
			return self.root
		}
	}
	
	private func indexPath(node: NCTreeControllerNode) -> IndexPath? {
		guard let item = node.item else {return IndexPath(row: -1, section: 0)}
		var row = 0
		
		func enumerate(_ node: NCTreeControllerNode) -> NCTreeControllerNode? {
			if node.expanded {
				for child in node.children {
					if let childItem = child.item as? AnyHashable, let item = item as? AnyHashable, childItem == item {
						return child
					}
					else if let childItem = child.item, childItem === item {
						return child
					}
					row += 1
					if let node = enumerate(child) {
						return node
					}
				}
			}
			return nil
		}
		if enumerate(self.root) != nil {
			return IndexPath(row: row, section: 0)
		}
		else {
			return nil
		}
	}

	private func indexPath(item: AnyObject) -> IndexPath? {
		var row = 0
		
		func enumerate(_ node: NCTreeControllerNode) -> NCTreeControllerNode? {
			if node.expanded {
				for child in node.children {
					if let childItem = child.item as? AnyHashable, let item = item as? AnyHashable, childItem == item {
						return child
					}
					else if let childItem = child.item, childItem === item {
						return child
					}
					row += 1
					if let node = enumerate(child) {
						return node
					}
				}
			}
			return nil
		}
		if enumerate(self.root) != nil {
			return IndexPath(row: row, section: 0)
		}
		else {
			return nil
		}
	}
	
	private func indexPaths(forChildren children: IndexSet, ofNode node:NCTreeControllerNode) -> [IndexPath] {
		guard let indexPath = self.indexPath(node: node) else {return []}
		guard let to = children.last else {return []}

		var array = [IndexPath]()
		var row = node.item != nil ? indexPath.row + 1 : 0
		
		for i in 0...to {
			let child = node.children[i]
			let contains = children.contains(i)
			if contains {
				array.append(IndexPath(row: row, section: 0))
			}
			row += 1
			if child.expanded {
				let n = numberOfRows(node: child)
				if contains {
					for _ in 0..<n {
						array.append(IndexPath(row: row, section:0))
						row += 1
					}
				}
				else {
					row += n
				}
			}
		}
		
		return array
	}
	
	fileprivate func reloadChildren(_ children: IndexSet, ofNode node: NCTreeControllerNode, withRowAnimation animation: UITableViewRowAnimation) {
		var array = [IndexPath]()
		
		for index in children {
			if let indexPath = indexPath(node: node.children[index]) {
				array.append(indexPath)
			}
		}
		if array.count > 0 {
			self.tableView?.reloadRows(at: array, with: animation)
		}
	}
	
	fileprivate func insertChildren(_ children: IndexSet, ofNode node: NCTreeControllerNode, withRowAnimation animation: UITableViewRowAnimation) {
		
		assert(self.content != nil || self.delegate!.treeController!(self, numberOfChildrenOfItem: node.item) == node.children.count + children.count)
		node.insertChildren(children)

		if node.item == nil || (indexPath(node: node) != nil && node.expanded) {
			_numberOfRows = nil
			self.tableView?.insertRows(at: indexPaths(forChildren: children, ofNode: node), with: animation)
		}
	}
	
	fileprivate func deleteChildren(_ children: IndexSet, ofNode node: NCTreeControllerNode, withRowAnimation animation: UITableViewRowAnimation) {
		
		assert(self.content != nil || self.delegate!.treeController!(self, numberOfChildrenOfItem: node.item) == node.children.count + children.count)
		
		if node.item == nil || (indexPath(node: node) != nil && node.expanded) {
			let array = indexPaths(forChildren: children, ofNode: node)
			_numberOfRows = nil
			node.removeChildren(children)
			self.tableView?.deleteRows(at: array, with: animation)
		}
		else {
			node.removeChildren(children)
		}
	}
}
