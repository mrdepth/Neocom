//
//  TreeController.swift
//  TreeController
//
//  Created by Artem Shimanski on 06.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

public enum ChangeType {
	case insert
	case delete
	case move
	case update
}

public enum TransitionStyle {
	case none
	case reload
	case reconfigure
}

extension Array where Element: TreeNode {
	func changes(from: Array<Element>, handler: (_ oldIndex: Index?, _ newIndex: Index?, _ changeType: ChangeType) -> Void) {
		let to = self
		var arr = from
		
		for (i, v) in from.enumerated().reversed() {
			if to.index(of: v) == nil {
				handler(i, nil, .delete)
				arr.remove(at: i)
			}
		}
		
		for i in indices {
			let obj = to[i]
			if let j = arr[i..<arr.count].index(of: obj) {
				let k = from.index(of: obj)!
				
				if j != i {
					handler(k, i, .move)
				}
				let obj2 = from[k]
				if obj !== obj2 {
					handler(k, i, .update)
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

open class TreeNode: NSObject {
	var cellIdentifier: String?
	func configure(cell: UITableViewCell) -> Void {
		cell.indentationLevel = indentationLevel
	}
	
	init(cellIdentifier: String? = nil) {
		self.cellIdentifier = cellIdentifier
		super.init()
	}
	
	private var oldRange: CountableRange<Int>?
	var children: [TreeNode]? {
		willSet {
			if treeController != nil, let index = flatIndex {
				oldRange = index..<(index + size)
			}
		}
		didSet {
			for child in children ?? [] {
				child.parent = self
			}
			if isLoaded, let treeController = treeController, let oldRange = oldRange {
				treeController.replaceNodes(at: oldRange, with: flattened)
			}
			oldRange = nil
			isLoaded = true
		}
	}
	
	weak var parent: TreeNode?
	weak var treeController: TreeController? {
		get {
			return _treeController ?? parent?.treeController
		}
		set {
			_treeController = newValue
		}
	}
	
	open var isExpandable: Bool {
		return true
	}
	
	var isExpanded: Bool = true {
		willSet {
			guard isExpanded else {return}
			guard newValue != isExpanded else {return}
			guard let treeController = treeController else {return}
			guard let flatIndex = flatIndex else {return}
			
			var range = flatIndex..<(flatIndex + size)
			if isViewable {
				range = (range.lowerBound + 1) ..< range.upperBound
			}
			treeController.removeNodes(at: range)
		}
		didSet {
			guard let treeController = treeController else {return}
			guard oldValue != isExpanded else {return}
			
			if let cell = treeController.cell(for: self) as? Expandable {
				cell.setExpanded(isExpanded, animated: true)
			}
			
			guard isExpanded else {return}
			guard var flatIndex = flatIndex else {return}
			
			var array = flattened
			if isViewable {
				flatIndex += 1
				array = Array(array[1..<array.count])
			}
			
			treeController.insertNodes(array, at: flatIndex)
		}
	}

	func transitionStyle(from node: TreeNode) -> TransitionStyle {
		return .none
	}
	
	func loadChildren() {
		
	}
	
	private var isLoaded: Bool = false
	private weak var _treeController: TreeController?
	fileprivate var isViewable: Bool {
		return cellIdentifier != nil
	}
	fileprivate var estimatedHeight: CGFloat?
	
	fileprivate var flatIndex: Int?
	fileprivate var size: Int {
		var size = isViewable ? 1 : 0
		if !isExpandable || isExpanded || !isViewable {
			if !isLoaded {
				loadChildren()
				isLoaded = true
			}
			
			for child in children ?? [] {
				size += child.size
			}
		}
		return size
	}
	
	fileprivate var flattened: [TreeNode] {
		
		if !isExpandable || isExpanded || !isViewable {
			if !isLoaded {
				loadChildren()
				isLoaded = true
			}
			
			var array = [TreeNode]()
			if isViewable {
				array.append(self)
			}
			
			for child in children ?? [] {
				array.append(contentsOf: child.flattened)
			}
			
			return array
		}
		else if isViewable {
			return [self]
		}
		else {
			return []
		}
	}
	
	fileprivate var indentationLevel: Int {
		return parent?.isViewable == true ? parent!.indentationLevel + 1 : parent?.indentationLevel ?? 0
	}
}

@objc public protocol TreeControllerDelegate {
	@objc optional func treeController(_ treeController: TreeController, configureCell cell: UITableViewCell, withNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]?
	@objc optional func treeController(_ treeController: TreeController, editingStyleForNode node: TreeNode) -> UITableViewCellEditingStyle
	@objc optional func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, didExpandCellWithNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, didCollapseCellWithNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) -> Void
	@objc optional func treeController(_ treeController: TreeController, commit editingStyle: UITableViewCellEditingStyle, forNode node: TreeNode) -> Void
	
	@objc optional func treeControllerDidUpdateContent(_ treeController: TreeController) -> Void
}

@objc protocol Expandable {
	func setExpanded(_ expanded: Bool, animated: Bool) -> Void
}

open class TreeController: NSObject, UITableViewDelegate, UITableViewDataSource {
	
	var content: TreeNode? {
		didSet {
			content?.treeController = self
			let to = content?.flattened
			if oldValue == nil {
				flattened = to ?? []
				updateIndexes()
				tableView.reloadData()
			}
			else {
				replaceNodes(at: 0..<flattened.count, with: to ?? [])
			}
		}
	}
	
	@IBOutlet public weak var tableView: UITableView!
	@IBOutlet public weak var delegate: TreeControllerDelegate?
	
	private var flattened: [TreeNode] = []

	public func cell(for node: TreeNode) -> UITableViewCell? {
		guard let index = node.flatIndex else {return nil}
		let indexPath = IndexPath(row: index, section: 0)
		return tableView.cellForRow(at: indexPath)
	}
	
	public func node(for cell: UITableViewCell) -> TreeNode? {
		guard let indexPath = tableView.indexPath(for: cell) else {return nil}
		return flattened[indexPath.row]
	}
	
	public func indexPath(for node: TreeNode) -> IndexPath? {
		guard let index = node.flatIndex else {return nil}
		return IndexPath(row: index, section: 0)
	}
	
	public func reloadCells(for nodes: [TreeNode]) {
		let indexPaths = nodes.flatMap({$0.flatIndex == nil ? nil : IndexPath(row: $0.flatIndex!, section:0)})
		if (indexPaths.count > 0) {
			tableView.reloadRows(at: indexPaths, with: .fade)
		}
	}
	
	public func deselectCell(for node: TreeNode, animated: Bool) {
		guard let index = node.flatIndex else {return}
		let indexPath = IndexPath(row: index, section: 0)
		tableView.deselectRow(at: indexPath, animated: animated)
	}
	
	public func selectCell(for node: TreeNode, animated: Bool, scrollPosition: UITableViewScrollPosition) {
		guard let index = node.flatIndex else {return}
		let indexPath = IndexPath(row: index, section: 0)
		tableView.selectRow(at: indexPath, animated: animated, scrollPosition: scrollPosition)
	}
	
	
	private var updatesCounter: Int = 0
	
	public func beginUpdates() {
		tableView.beginUpdates()
		updatesCounter += 1
	}
	
	public func endUpdates() {
		tableView.endUpdates()
		updatesCounter -= 1
		if updatesCounter == 0 {
			delegate?.treeControllerDidUpdateContent?(self)
		}
	}

	
	//MARK: - UITableViewDataSource
	
	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return flattened.count
	}
	
	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let node = flattened[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: node.cellIdentifier!, for: indexPath)
		cell.indentationLevel = node.indentationLevel
		
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
		let node = flattened[indexPath.row]
		delegate?.treeController?(self, commit: editingStyle, forNode: node)
	}
	
	//MARK: - UITableViewDelegate
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let node = flattened[indexPath.row]
		if node.isExpandable {
			node.isExpanded = !node.isExpanded
		}
		
		delegate?.treeController?(self, didSelectCellWithNode: node)
	}
	
	public func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
		let node = flattened[indexPath.row]
		delegate?.treeController?(self, accessoryButtonTappedWithNode: node)
	}
	
	
	public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let node = flattened[indexPath.row]
		return delegate?.treeController?(self, editActionsForNode: node)
	}
	
	public func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		let node = flattened[indexPath.row]
		return delegate?.treeController?(self, editingStyleForNode: node) ?? (self.tableView(tableView, editActionsForRowAt: indexPath) != nil ? .delete : .none)
	}
	
	public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return self.tableView(tableView, editingStyleForRowAt: indexPath) != .none
	}
	
	public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		let node = flattened[indexPath.row]
		if let estimatedHeight = node.estimatedHeight {
			return estimatedHeight
		}
		else {
			return tableView.estimatedRowHeight > 0 ? tableView.estimatedRowHeight : UITableViewAutomaticDimension
		}
	}
	
	public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let node = flattened[indexPath.row]
		node.estimatedHeight = cell.bounds.size.height
	}
	
	
	
	//MARK - Private
	
	fileprivate func removeNodes(at range: CountableRange<Int>) {
		for node in flattened[range] {
			node.flatIndex = nil
		}
		flattened.removeSubrange(range)
//		var i = range.lowerBound
//		for node in flattened?[range.lowerBound ..< flattened!.count] ?? [] {
//			node.flatIndex = i
//			i += 1
//		}
		updateIndexes()
		
		tableView.deleteRows(at: range.map({IndexPath(row: $0, section: 0)}), with: .automatic)
	}
	
	fileprivate func insertNodes(_ nodes: [TreeNode], at index: Int) {
		flattened.insert(contentsOf: nodes, at: index)
//		var i = index
//		for node in flattened?[index ..< flattened!.count] ?? [] {
//			node.flatIndex = i
//			i += 1
//		}
		updateIndexes()
		let range = index..<(index + nodes.count)
		tableView.insertRows(at: range.map({IndexPath(row: $0, section: 0)}), with: .automatic)
	}
	
	fileprivate func replaceNodes(at range: CountableRange<Int>, with nodes: [TreeNode]) {
		beginUpdates()

		let from = Array(flattened[range])
		flattened.replaceSubrange(range, with: nodes)
		
		let start = range.lowerBound
		nodes.changes(from: from) { (old, new, type) in
			switch type {
			case .insert:
				tableView.insertRows(at: [IndexPath(row: start + new!, section: 0)], with: .automatic)
			case .delete:
				tableView.deleteRows(at: [IndexPath(row: start + old!, section: 0)], with: .automatic)
			case .move:
				tableView.moveRow(at: IndexPath(row: start + old!, section: 0), to: IndexPath(row: new!, section: 0))
			case .update:
				let a = from[old!]
				let b = nodes[new!]
				switch b.transitionStyle(from: a) {
				case .reload:
					tableView.reloadRows(at: [IndexPath(row: start + old!, section: 0)], with: .fade)
				case .reconfigure:
					tableView.reloadRows(at: [IndexPath(row: start + old!, section: 0)], with: .none)
				default:
					break
				}
			}
		}
		
//		var i = range.lowerBound
//		for node in flattened?[range.lowerBound ..< flattened!.count] ?? [] {
//			node.flatIndex = i
//			i += 1
//		}
		updateIndexes()
		endUpdates()
	}
	
	fileprivate func updateIndexes() {
		guard let content = content else {return}
		var index: Int = 0
		func update(_ node: TreeNode) {
			node.flatIndex = index
			if node.isViewable {
				index += 1
			}
			
			if !node.isExpandable || node.isExpanded || !node.isViewable {
				for child in node.children ?? [] {
					update(child)
				}
			}
		}
		update(content)
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
		if resultsController.fetchRequest.resultType == .managedObjectResultType || resultsController.fetchRequest.resultType == .managedObjectResultType {
			resultsController.delegate = self
		}
	}
	
	override func loadChildren() {
		try? resultsController.performFetch()
		if let sectionNode = self.sectionNode {
			children = resultsController.sections?.map {sectionNode.init(section: $0, objectNode: self.objectNode)}
		}
		else {
			children = resultsController.fetchedObjects?.flatMap {objectNode.init(object: $0)}
		}
	}
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		treeController?.beginUpdates()
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
		treeController?.endUpdates()
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
	
	override func loadChildren() {
		children = section.objects?.flatMap {objectNode.init(object: $0 as! ResultType)}
	}
	
	override var hashValue: Int {
		return section.name.hashValue ^ section.numberOfObjects.hashValue
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
	
}
