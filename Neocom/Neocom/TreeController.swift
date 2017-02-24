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
			if let j = arr[i..<arr.count].index(of: obj) {
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

extension IndexPath {
	static func indexPaths(rows: CountableRange<Int>, section: Int) -> [IndexPath] {
		var indexPaths = [IndexPath]()
		for i in rows {
			indexPaths.append(IndexPath(row: i, section: section))
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
	}
}

public enum TreeNodeReloading {
	case dontReload
	case reload
	case reconfigure
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
			size = nil
			if !disableTransitions, let from = from {
				performTransition(from: from)
//				if let tableView = treeController?.tableView, let indexPath = self.indexPath, indexPath.row >= 0 {
//					if self.changed(from: self) {
//						tableView.reloadRows(at: [indexPath], with: .fade)
//					}
//				}
			}
			from = nil
		}
	}
	
	private func performTransition(from: TreeNode?) {
		if isExpanded, let tableView = treeController?.tableView, indexPath != nil, from?.indexPath != nil {
			let from = from?.isExpanded == true ? from?.children ?? [] : []
			tableView.beginUpdates()
			(children ?? []).changes(from: from, handler: { (old, new, type) in
				switch type {
				case .insert:
					let rows = children![new!].indexPaths
					tableView.insertRows(at: rows, with: .fade)
				case .delete:
					let rows = from[old!].indexPaths
					tableView.deleteRows(at: rows, with: .fade)
				case .move:
					let oldRows = from[old!].indexPaths
					tableView.deleteRows(at: oldRows, with: .fade)
					let newRows = children![new!].indexPaths
					tableView.insertRows(at: newRows, with: .fade)
				case .update:
					guard let to = children?[new!] else {break}
					let oldNode = from[old!]
					to.estimatedHeight = oldNode.estimatedHeight
					to.performTransition(from: oldNode)
					
					switch (to.move(from: oldNode), oldNode.indexPath) {
					case (.reload, let indexPath?):
						tableView.reloadRows(at: [indexPath], with: .fade)
					case (.reconfigure, _):
						guard let cell = treeController?.cell(for: to) else {break}
						to.configure(cell: cell)
					default:
						break
					}
					
					break
				}
			})
			tableView.endUpdates()
		}
	}
	
	open var cellIdentifier: String?
	
	private var _size: Int? = nil
	fileprivate var size: Int! {
		get {
			if _size == nil {
				if self.children == nil {
					_lazyLoad()
				}
				var size = isDummy ? 0 : 1
				if isExpanded {
					for child in self.children ?? [] {
						size += child.size
					}
				}
				_size = size
			}
			return _size!
		}
		set {
			if newValue == nil && (parent?.isExpanded == true || parent?.isDummy == true) {
				{parent?.size = nil} ()
			}

			_size = newValue
		}
	}
	
	open var isExpandable: Bool {
		return false
	}
	
	private var isDummy: Bool {
		return cellIdentifier == nil
	}
	
	open func lazyLoad() {
		
	}
	
	private var disableTransitions: Bool = false
	private func _lazyLoad() {
		disableTransitions = true
		lazyLoad()
		disableTransitions = false
	}
	
	func move(from: TreeNode) -> TreeNodeReloading {
		return .dontReload
	}

	open var isExpanded: Bool = true {
		didSet {
			guard !isDummy else {return}
			
			if children == nil {
				if isExpanded {
					lazyLoad()
				}
			}
			else {
				if oldValue != isExpanded {
					size = nil
					
					if let tableView = treeController?.tableView, let indexPath = indexPath {
						
						if let cell = tableView.cellForRow(at: indexPath) as? Expandable {
							cell.setExpanded(isExpanded, animated: true)
						}
						
						var size = 0
						for child in self.children ?? [] {
							size += child.size
						}
						let rows = IndexPath.indexPaths(rows: (indexPath.row + 1)..<(indexPath.row + 1 + size), section: 0)
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
		guard size > index else {return nil}
		if index == 0 && !isDummy {
			return self
		}
		guard isExpanded else {return nil}
		
		var i = isDummy ? index : index - 1
		for child in children ?? [] {
			if let result = child.node(at: i) {
				return result
			}
			else {
				i -= child.size
			}
		}
		return nil
	}
	
	open func configure(cell: UITableViewCell) {
	}
	
	public var indexPath: IndexPath? {
		if parent == nil {
			return IndexPath(row: 0, section: 0)
		}
		else if parent?.isExpanded == true {
			guard var indexPath = parent?.indexPath else {return nil}
			if parent?.isDummy == false {
				indexPath.row += 1
			}

			for child in parent?.children ?? [] {
				guard child !== self else {break}
				indexPath.row += child.size
			}
			return indexPath

		}
		else {
			return nil
		}
		
		/*if parent == nil {
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
		return nil*/
	}
	
	public var indexPaths: [IndexPath] {
		guard let indexPath = self.indexPath else {return []}
		return IndexPath.indexPaths(rows: indexPath.row..<(indexPath.row + size), section: 0)
	}
	
	public var indentationLevel: Int? {
		if parent == nil {
			return -1
		}
		else if parent?.isExpanded == true {
			guard let level = parent?.indentationLevel else {return nil}
			return isDummy ? level : level + 1
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
//	@objc optional func treeController(_ treeController: TreeController, cellIdentifierForNode node: TreeNode) -> String?
	@objc optional func treeController(_ treeController: TreeController, configureCell cell: UITableViewCell, withNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]?
	@objc optional func treeController(_ treeController: TreeController, editingStyleForNode node: TreeNode) -> UITableViewCellEditingStyle
	@objc optional func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, didExpandCellWithNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, didCollapseCellWithNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) -> Void;
	@objc optional func treeController(_ treeController: TreeController, commit editingStyle: UITableViewCellEditingStyle, forNode node: TreeNode) -> Void;
	
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

	public func indexPath(for node: TreeNode) -> IndexPath? {
		return node.indexPath
	}

	public func reloadCells(for nodes: [TreeNode]) {
		let indexPaths = nodes.flatMap({$0.indexPath})
		if (indexPaths.count > 0) {
			tableView.reloadRows(at: indexPaths, with: .fade)
		}
	}

	public func deselectCell(for node: TreeNode, animated: Bool) {
		guard let indexPath = node.indexPath else {return}
		tableView.deselectRow(at: indexPath, animated: animated)
	}
	
	//MARK: - UITableViewDataSource
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return rootNode?.size ?? 0
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let node = rootNode!.node(at: indexPath.row)!
//		let cell = tableView.dequeueReusableCell(withIdentifier: delegate?.treeController?(self, cellIdentifierForNode: node) ?? node.cellIdentifier!)!
		let cell = tableView.dequeueReusableCell(withIdentifier: node.cellIdentifier!)!
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
	
	public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		guard let node = rootNode?.node(at: indexPath.row) else {return}
		delegate?.treeController?(self, commit: editingStyle, forNode: node)
	}
	
	//MARK: - UITableViewDelegate
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let node = rootNode?.node(at: indexPath.row) else {return}
		if node.isExpandable {
			node.isExpanded = !node.isExpanded
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
	
	public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		guard let node = rootNode?.node(at: indexPath.row) else {return .none}
		return delegate?.treeController?(self, editingStyleForNode: node) ?? (self.tableView(tableView, editActionsForRowAt: indexPath) != nil ? .delete : .none)
	}
	
	public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return self.tableView(tableView, editingStyleForRowAt: indexPath) != .none
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


class FetchedResultsNode<ResultType: NSFetchRequestResult>: TreeNode, NSFetchedResultsControllerDelegate {
	let resultsController: NSFetchedResultsController<ResultType>
	let sectionNode: FetchedResultsSectionNode<ResultType>.Type?
	let objectNode: FetchedResultsObjectNode<ResultType>.Type
	
	init(resultsController: NSFetchedResultsController<ResultType>, sectionNode: FetchedResultsSectionNode<ResultType>.Type? = nil, objectNode: FetchedResultsObjectNode<ResultType>.Type) {
		self.resultsController = resultsController
		self.sectionNode = sectionNode
		self.objectNode = objectNode
		super.init()
		resultsController.delegate = self
	}
	
	override func lazyLoad() {
		try? resultsController.performFetch()
		if let sectionNode = self.sectionNode {
			children = resultsController.sections?.map {sectionNode.init(section: $0, objectNode: self.objectNode)}
		}
		else {
			children = resultsController.fetchedObjects?.flatMap {objectNode.init(object: $0)}
		}
	}
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		treeController?.tableView.beginUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		guard let sectionNode = self.sectionNode else {return}
		switch type {
		case .insert:
			children?.insert(sectionNode.init(section: sectionInfo, objectNode: self.objectNode), at: sectionIndex)
		case .delete:
			children?.remove(at: sectionIndex)
		default:
			break
		}
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		guard self.sectionNode == nil else {return}
		switch type {
		case .insert:
			children?.insert(objectNode.init(object: anObject as! ResultType), at: newIndexPath!.row)
		case .delete:
			children?.remove(at: indexPath!.row)
		case .move:
			children?.remove(at: indexPath!.row)
			children?.insert(objectNode.init(object: anObject as! ResultType), at: newIndexPath!.row)
		case .update:
			children?[newIndexPath!.row] = objectNode.init(object: anObject as! ResultType)
		}
	}

	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		treeController?.tableView.endUpdates()
//		if let sectionNode = self.sectionNode {
//			children = resultsController.sections?.map {sectionNode.init(section: $0, objectNode: self.objectNode)}
//		}
//		else {
//			children = resultsController.fetchedObjects?.flatMap {objectNode.init(object: $0)}
//		}
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
	
	override var hashValue: Int {
		return [section.name.hashValue, section.numberOfObjects].hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? FetchedResultsSectionNode<ResultType>)?.hashValue == hashValue
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
