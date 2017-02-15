//
//  TreeController.swift
//  Neocom
//
//  Created by Artem Shimanski on 30.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

public enum ChangeType : UInt {
	case insert
	case delete
	case move
	case update
}


extension Array where Element: TreeNode {
	func changes(from: Array<Element>, handler: (_ oldIndex: Int?, _ newIndex: Int?, _ changeType: ChangeType) -> Void) {
		let to = self
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
				arr.insert(obj, at: i)
			}
		}
	}
	
	mutating func remove(at: IndexSet) {
		for i in at.reversed() {
			self.remove(at: i)
		}
	}
	
	func descendantIndexesOfItem(at index: Int) -> IndexSet {
		var n = 0
		var i = 0
		var indexes = IndexSet()
		for child in self {
			if i >= index {
				if child.isExpanded {
					indexes.insert(integersIn: n...(n + child.descendantCount))
				}
				else {
					indexes.insert(index)
				}
				break
			}
			else {
				if child.isExpanded {
					n += child.descendantCount
				}
			}
			n += 1
			i += 1
		}
		return indexes
	}
}

extension IndexSet {
	func indexPaths(rowsShift: Int = 0, section: Int = 0) -> [IndexPath] {
		var indexPaths = [IndexPath]()
		for i in self {
			indexPaths.append(IndexPath(row: i + rowsShift, section: section))
		}
		return indexPaths
	}
}

private class TreeNodeSnapshot: TreeNode {
	let _indexPath: IndexPath?
	override var indexPath: IndexPath? {
		return _indexPath
	}
	
	init(node: TreeNode) {
		_indexPath = node.indexPath
		super.init()
		isExpanded = node.isExpanded
		self.children = node.children
//		if (isExpanded) {
//			self.children = node.children?.map({TreeNodeSnapshot(node: $0)})
//		}
	}
}

open class TreeNode: NSObject {
	
	public init(cellIdentifier: String? = nil) {
		self.cellIdentifier = cellIdentifier
		super.init()
	}
	
	var from: TreeNode?
	open var children: [TreeNode]? {
		willSet {
			if !disableTransitions && !(self is TreeNodeSnapshot) {
				from = TreeNodeSnapshot(node: self)
			}
		}
		didSet {
			var index = 0
			for child in children ?? [] {
				child.parent = self
				child.index = index
				index += 1
			}
			descendantCount = nil
			if !disableTransitions, let from = from {
				performTransition(from: from)
				if let tableView = treeController?.tableView, let indexPath = self.indexPath, indexPath.row >= 0 {
					tableView.reloadRows(at: [indexPath], with: .fade)
				}
			}
			from = nil
		}
	}
	
	private func performTransition(from: TreeNode?) {
		if isExpanded, let tableView = treeController?.tableView, let toIndexPath = indexPath, let fromIndexPath = from?.indexPath {
			let from = from?.isExpanded == true ? from?.children ?? [] : []
			tableView.beginUpdates()
			(children ?? []).changes(from: from, handler: { (old, new, type) in
				switch type {
				case .insert:
					let rows = children!.descendantIndexesOfItem(at: new!).indexPaths(rowsShift: toIndexPath.row + 1, section: 0)
					tableView.insertRows(at: rows, with: .fade)
				case .delete:
					let rows = from.descendantIndexesOfItem(at: old!).indexPaths(rowsShift: fromIndexPath.row + 1, section: 0)
					tableView.deleteRows(at: rows, with: .fade)
				case .move:
					let oldRows = from.descendantIndexesOfItem(at: old!).indexPaths(rowsShift: fromIndexPath.row + 1, section: 0)
					tableView.deleteRows(at: oldRows, with: .fade)
					let newRows = children!.descendantIndexesOfItem(at: new!).indexPaths(rowsShift: toIndexPath.row + 1, section: 0)
					tableView.insertRows(at: newRows, with: .fade)
				case .update:
					guard let to = children?[new!] else {break}
					let oldNode = from[old!]
					to.estimatedHeight = oldNode.estimatedHeight
					to.performTransition(from: oldNode)
					
					if to.changed(from: oldNode), let indexPath = oldNode.indexPath {
						tableView.reloadRows(at: [indexPath], with: .fade)
					}
					break
				}
			})
			tableView.endUpdates()
		}
	}
	
	open var cellIdentifier: String?
	
	private var _descendantCount: Int? = nil
	
	fileprivate var descendantCount: Int! {
		get {
			if _descendantCount == nil {
				if self.children == nil {
					_lazyLoad()
				}
				
				var count = 0
				for child in self.children ?? [] {
					count += 1
					if child.isExpanded {
						count += child.descendantCount ?? 0
					}
				}
				_descendantCount = count
			}
			return _descendantCount!
		}
		set {
			if isExpanded {
				if newValue == nil {
					{parent?.descendantCount = nil} ()
				}
			}
			_descendantCount = newValue
		}
	}
	
	open var isExpandable: Bool {
		return false
	}
	
	open func lazyLoad() {
		
	}
	
	private var disableTransitions: Bool = false
	private func _lazyLoad() {
		disableTransitions = true
		lazyLoad()
		disableTransitions = false
	}
	
	open func changed(from: TreeNode) -> Bool {
		return isExpanded != from.isExpanded
	}
	
	open var isExpanded: Bool = true {
		didSet {
			if children == nil {
				if isExpanded {
					lazyLoad()
				}
			}
			else {
				if oldValue != isExpanded {
					//parent?.descendantCount += isExpanded ? descendantCount : -descendantCount
					parent?.descendantCount = nil
					
					if let tableView = treeController?.tableView, let indexPath = indexPath {
						let rows = IndexSet(integersIn: 1...descendantCount).indexPaths(rowsShift: indexPath.row, section: 0)
						if isExpanded {
							tableView.insertRows(at: rows, with: .automatic)
						}
						else {
							tableView.deleteRows(at: rows, with: .automatic)
						}
					}
				}
			}
		}
	}
	
	open func node(at index: Int) -> TreeNode? {
		guard descendantCount >= index else {return nil}
		var i = index
		for child in children ?? [] {
			if i == 0 {
				return child
			}
			else {
				i -= 1
				if child.isExpanded {
					if let result = child.node(at: i) {
						return result
					}
					else {
						i -= child.descendantCount
					}
				}
			}
		}
		return nil
	}
	
	open func configure(cell: UITableViewCell) {
	}
	
	public var indexPath: IndexPath? {
		if parent == nil {
			return IndexPath(row: -1, section: 0)
		}
		else if parent?.isExpanded == true {
			guard var indexPath = parent?.indexPath else {return nil}
			indexPath.row += 1
			var i = 0
			for child in parent?.children ?? [] {
				guard i < index else {break}
				if child.isExpanded {
					indexPath.row += child.descendantCount
				}
				indexPath.row += 1
				i += 1
			}
			return indexPath
		}
		return nil
	}
	
	public var indentationLevel: Int? {
		if parent == nil {
			return -1
		}
		else if parent?.isExpanded == true {
			guard let level = parent?.indentationLevel else {return nil}
			return level + 1
		}
		return nil
	}
	
	private(set) public weak var parent: TreeNode?
	private(set) public var index: Int = 0
	
	private weak var _treeController: TreeController?
	fileprivate(set) public weak var treeController: TreeController? {
		set {
			_treeController = newValue
		}
		get {
			return _treeController ?? parent?.treeController
		}
	}
	fileprivate var estimatedHeight: CGFloat?
}

@objc public protocol TreeControllerDelegate {
	@objc optional func treeController(_ treeController: TreeController, cellIdentifierForNode node: TreeNode) -> String?
	@objc optional func treeController(_ treeController: TreeController, configureCell cell: UITableViewCell, withNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]?
	@objc optional func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, didExpandCellWithNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, didCollapseCellWithNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) -> Void;
	
}

@objc protocol Expandable {
	func setExpanded(_ expanded: Bool, animated: Bool) -> Void
}

public class TreeController: NSObject, UITableViewDelegate, UITableViewDataSource {
	public var rootNode: TreeNode? {
		didSet {
			rootNode?.treeController = self
			tableView.reloadData()
		}
	}
	@IBOutlet public weak var tableView: UITableView!
	@IBOutlet public weak var delegate: TreeControllerDelegate?
	
	public func cell(for node: TreeNode) -> UITableViewCell? {
		guard let indexPath = node.indexPath else {return nil}
		return tableView.cellForRow(at: indexPath)
	}
	
	public func node(for cell: UITableViewCell) -> TreeNode? {
		guard let indexPath = tableView.indexPath(for: cell) else {return nil}
		return rootNode?.node(at: indexPath.row)
	}
	
	public func reloadCells(for nodes: [TreeNode]) {
		let indexPaths = nodes.flatMap({$0.indexPath})
		if (indexPaths.count > 0) {
			tableView.reloadRows(at: indexPaths, with: .fade)
		}
	}

	
	//MARK: - UITableViewDataSource
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return rootNode?.descendantCount ?? 0
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let node = rootNode!.node(at: indexPath.row)!
		let cell = tableView.dequeueReusableCell(withIdentifier: delegate?.treeController?(self, cellIdentifierForNode: node) ?? node.cellIdentifier!)!
		cell.indentationLevel = node.indentationLevel ?? 0
		
		if let cell = cell as? Expandable {
			cell.setExpanded(node.isExpanded, animated: false)
		}

		node.configure(cell: cell)
		delegate?.treeController?(self, configureCell: cell, withNode: node)
		return cell
	}
	
	public func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	//MARK: - UITableViewDelegate
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let node = rootNode?.node(at: indexPath.row) else {return}
		if node.isExpandable {
			node.isExpanded = !node.isExpanded
			if let cell = tableView.cellForRow(at: indexPath) as? Expandable {
				cell.setExpanded(node.isExpanded, animated: true)
			}
		}
		
		delegate?.treeController?(self, didSelectCellWithNode: node)
	}
	
	public func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
		guard let node = rootNode?.node(at: indexPath.row) else {return}
		delegate?.treeController?(self, accessoryButtonTappedWithNode: node)
	}
	
	
	public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		guard let node = rootNode?.node(at: indexPath.row) else {return nil}
		return delegate?.treeController?(self, editActionsForNode: node)
	}
	
	public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return self.tableView(tableView, editActionsForRowAt: indexPath) != nil
	}
	
	public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		guard let node = rootNode?.node(at: indexPath.row) else {return UITableViewAutomaticDimension}
		if let estimatedHeight = node.estimatedHeight {
			return estimatedHeight
		}
		else {
			return tableView.estimatedRowHeight > 0 ? tableView.estimatedRowHeight : UITableViewAutomaticDimension
		}
	}
	
	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		guard let node = rootNode?.node(at: indexPath.row) else {return}
		node.estimatedHeight = cell.bounds.size.height
	}
}


class FetchedResultsNode<ResultType: NSFetchRequestResult>: TreeNode {
	let resultsController: NSFetchedResultsController<ResultType>
	let sectionNode: FetchedResultsSectionNode<ResultType>.Type
	let objectNode: FetchedResultsObjectNode<ResultType>.Type
	
	required init(resultsController: NSFetchedResultsController<ResultType>, sectionNode: FetchedResultsSectionNode<ResultType>.Type, objectNode: FetchedResultsObjectNode<ResultType>.Type) {
		self.resultsController = resultsController
		self.sectionNode = sectionNode
		self.objectNode = objectNode
		super.init()
	}
	
	override func lazyLoad() {
		children = resultsController.sections?.map {self.sectionNode.init(section: $0, objectNode: self.objectNode)}
	}
	
}

class FetchedResultsSectionNode<ResultType: NSFetchRequestResult> : TreeNode {
	let section: NSFetchedResultsSectionInfo
	let objectNode: FetchedResultsObjectNode<ResultType>.Type
	required init(section: NSFetchedResultsSectionInfo, objectNode: FetchedResultsObjectNode<ResultType>.Type) {
		self.objectNode = objectNode
		self.section = section
		super.init()
	}
	
	override func lazyLoad() {
		children = section.objects?.flatMap {objectNode.init(object: $0 as! ResultType)}
	}
}

class FetchedResultsObjectNode<ResultType: NSFetchRequestResult>: TreeNode {
	let object: ResultType
	
	required init(object: ResultType) {
		self.object = object
		super.init()
	}
	
	override var hashValue: Int {
		return object.hash
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? FetchedResultsObjectNode<ResultType>)?.hashValue == hashValue
	}
	
	override var isExpandable: Bool {
		return false
	}
}


//let l: FetchedResultsSectionNode<FetchedResultsObjectNode<NSDictionary>>? = nil
