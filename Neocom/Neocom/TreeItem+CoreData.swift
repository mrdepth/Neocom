//
//  TreeItem+CoreData.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import TreeController
import Expressible

//protocol FetchedResultsControllerTreeItemProtocol: class {
//	var treeController: TreeController? {get}
//}
//
//
//protocol FetchedResultsSectionTreeItemProtocol: class {
//	var controller: FetchedResultsControllerTreeItemProtocol? {get}
//}

protocol FetchedResultsControllerProtocol: class {
	var treeController: TreeController? {get}
	var diffIdentifier: AnyHashable {get}
}

protocol FetchedResultsSectionProtocol: class {
	/*weak*/ var controller: FetchedResultsControllerProtocol? {get}
}

protocol FetchedResultsSectionTreeItem: TreeItem, FetchedResultsSectionProtocol where Child: FetchedResultsTreeItem {
	var sectionInfo: NSFetchedResultsSectionInfo {get}
	var children: [Child]? {get set}
	init(_ sectionInfo: NSFetchedResultsSectionInfo, controller: FetchedResultsControllerProtocol)
}

protocol FetchedResultsTreeItem: TreeItem {
	associatedtype Result: NSFetchRequestResult & Equatable
	var result: Result {get}
	/*weak*/ var section: FetchedResultsSectionProtocol? {get set}
	
	init(_ result: Result, section: FetchedResultsSectionProtocol)
}

//extension FetchedResultsTreeItem {
//	var hashValue: Int {
//		return result.hash
//	}
//
//	var diffIdentifier: Result {
//		return result
//	}
//
//	static func == (lhs: Self, rhs: Self) -> Bool {
//		return lhs.result == rhs.result
//	}
//
//}

extension Tree.Item {
	class FetchedResultsController<Section: FetchedResultsSectionTreeItem>: NSObject, TreeItem, NSFetchedResultsControllerDelegate, FetchedResultsControllerProtocol {
		var fetchedResultsController: NSFetchedResultsController<Section.Child.Result>
		weak var treeController: TreeController?
		
		override var hash: Int {
			return fetchedResultsController.fetchRequest.hash
		}

		typealias DiffIdentifier = AnyHashable
		var diffIdentifier: AnyHashable
		
		lazy var children: [Section]? = {
			if fetchedResultsController.fetchedObjects == nil {
				try? fetchedResultsController.performFetch()
			}
			return fetchedResultsController.sections?.map {Child($0, controller: self)}
		}()
		
		init<T: Hashable>(_ fetchedResultsController: NSFetchedResultsController<Section.Child.Result>, diffIdentifier: T, treeController: TreeController?) {
			self.fetchedResultsController = fetchedResultsController
			self.diffIdentifier = AnyHashable(diffIdentifier)
			self.treeController = treeController
			super.init()
			if fetchedResultsController.fetchRequest.resultType == .managedObjectResultType {
				fetchedResultsController.delegate = self
			}
		}
		
		convenience init(_ fetchedResultsController: NSFetchedResultsController<Section.Child.Result>, treeController: TreeController?) {
			self.init(fetchedResultsController, diffIdentifier: fetchedResultsController.fetchRequest, treeController: treeController)
		}

		static func == (lhs: Tree.Item.FetchedResultsController<Section>, rhs: Tree.Item.FetchedResultsController<Section>) -> Bool {
			return lhs.fetchedResultsController.fetchRequest == rhs.fetchedResultsController.fetchRequest
		}
		
		override func isEqual(_ object: Any?) -> Bool {
			guard let rhs = object as? FetchedResultsController<Section> else {return false}
			return fetchedResultsController.fetchRequest == rhs.fetchedResultsController.fetchRequest
		}
		
		private struct Updates {
			var sectionInsertions = [(Int, NSFetchedResultsSectionInfo)]()
			var sectionDeletions = IndexSet()
			var itemInsertions = [(IndexPath, Any)]()
			var itemDeletions = [IndexPath]()
			
			var isEmpty: Bool {
				return sectionInsertions.isEmpty && sectionDeletions.isEmpty && itemInsertions.isEmpty && itemDeletions.isEmpty && itemUpdates.isEmpty
			}
			var itemUpdates = [(IndexPath, Any)]()
		}
		private var updates: Updates?
		
		func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
			updates = Updates()
		}
		
		func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
			switch type {
			case .insert:
				updates?.itemInsertions.append((newIndexPath!, anObject))
			case .delete:
				updates?.itemDeletions.append(indexPath!)
			case .move:
				updates?.itemDeletions.append(indexPath!)
				updates?.itemInsertions.append((newIndexPath!, anObject))
			case .update:
				updates?.itemUpdates.append((newIndexPath!, anObject))
			}
		}
		
		func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
			switch type {
			case .insert:
				updates?.sectionInsertions.append((sectionIndex, sectionInfo))
			case .delete:
				updates?.sectionDeletions.insert(sectionIndex)
			default:
				break
			}
		}
		
		func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
			updates?.itemDeletions.sorted().reversed().forEach {
				children![$0.section].children?.remove(at: $0.item)
			}
			updates?.sectionDeletions.rangeView.reversed().forEach { children!.removeSubrange($0) }
			
			updates?.sectionInsertions.sorted {$0.0 < $1.0}.forEach {
				children!.insert(Section($0.1, controller: self), at: $0.0)
			}
			updates?.itemInsertions.sorted {$0.0 < $1.0}.forEach { i in
				let section = children![i.0.section]
				
				if var item = i.1 as? Section.Child {
					item.section = section
					section.children!.insert(item, at: i.0.item)
				}
				else if let result = i.1 as? Section.Child.Result {
					let item = Section.Child(result, section: section)
					section.children!.insert(item, at: i.0.item)
				}
			}
			updates?.itemUpdates.forEach { i in
				let section = children![i.0.section]
				section.children!.remove(at: i.0.item)
				
				let item = Section.Child(i.1 as! Section.Child.Result, section: section)
				children![i.0.section].children!.insert(item, at: i.0.item)
			}
			
			if updates?.isEmpty == false {
				treeController?.update(contentsOf: self, with: .fade)
			}
			updates = nil
		}
	}
	
	class FetchedResultsSection<Item: FetchedResultsTreeItem>: TreeItem, FetchedResultsSectionTreeItem {
		func isEqual(_ other: FetchedResultsSection<Item>) -> Bool {
			return type(of: self) == type(of: other) && sectionInfo.name == other.sectionInfo.name && diffIdentifier == other.diffIdentifier
		}
		
		static func == (lhs: Tree.Item.FetchedResultsSection<Item>, rhs: Tree.Item.FetchedResultsSection<Item>) -> Bool {
			return lhs.isEqual(rhs)
		}
		
		weak var controller: FetchedResultsControllerProtocol?
		var diffIdentifier: AnyHashable
		var sectionInfo: NSFetchedResultsSectionInfo
		
		var hashValue: Int {
			return diffIdentifier.hashValue
		}

		lazy var children: [Item]? = sectionInfo.objects?.map{Item($0 as! Item.Result, section: self)}
		
		required init(_ sectionInfo: NSFetchedResultsSectionInfo, controller: FetchedResultsControllerProtocol) {
			self.sectionInfo = sectionInfo
			self.controller = controller
			self.diffIdentifier = [controller.diffIdentifier, sectionInfo.name]
		}
	}
	
	class FetchedResultsRow<Result: NSFetchRequestResult & Equatable & Hashable>: FetchedResultsTreeItem, CellConfiguring {
		var prototype: Prototype? {
			return (result as? CellConfiguring)?.prototype
		}
		
		func configure(cell: UITableViewCell) {
			(result as? CellConfiguring)?.configure(cell: cell)
		}
		
		var result: Result
		weak var section: FetchedResultsSectionProtocol?
		
		required init(_ result: Result, section: FetchedResultsSectionProtocol) {
			self.result = result
			self.section = section
		}
		
		var hashValue: Int {
			return result.hash
		}
		
		typealias DiffIdentifier = Result
		var diffIdentifier: Result {
			return result
		}
		
		func isEqual(_ other: FetchedResultsRow<Result>) -> Bool {
			return type(of: self) == type(of: other) && result == other.result
		}

		static func == (lhs: FetchedResultsRow<Result>, rhs: FetchedResultsRow<Result>) -> Bool {
			return lhs.isEqual(rhs)
		}
	}
	
	class NamedFetchedResultsController<Section: FetchedResultsSectionTreeItem>: FetchedResultsController<Section>, CellConfiguring, ExpandableItem {
		var isExpanded: Bool {
			get {
				return content.isExpanded
			}
			set {
				content.isExpanded = newValue
				if let cell = treeController?.cell(for: self) {
					content.configure(cell: cell)
				}
				treeController?.deselectCell(for: self, animated: true)
			}
		}

		var prototype: Prototype? {
			return content.prototype
		}
		
		var expandIdentifier: CustomStringConvertible?
		var content: Tree.Content.Section
		
		init<T: Hashable>(_ content: Tree.Content.Section, fetchedResultsController: NSFetchedResultsController<Section.Child.Result>, diffIdentifier: T, expandIdentifier: CustomStringConvertible? = nil, treeController: TreeController?) {
			self.expandIdentifier = expandIdentifier
			self.content = content
			super.init(fetchedResultsController, diffIdentifier: diffIdentifier, treeController: treeController)
		}

		convenience init(_ content: Tree.Content.Section, fetchedResultsController: NSFetchedResultsController<Section.Child.Result>, expandIdentifier: CustomStringConvertible? = nil, treeController: TreeController?) {
			self.init(content, fetchedResultsController: fetchedResultsController, diffIdentifier: fetchedResultsController.fetchRequest, expandIdentifier: expandIdentifier, treeController: treeController)
		}

		func configure(cell: UITableViewCell) {
			content.configure(cell: cell)
		}
	}
	
	class NamedFetchedResultsSection<Item: FetchedResultsTreeItem>: FetchedResultsSection<Item>, CellConfiguring, ExpandableItem {
		
		var isExpanded: Bool = true {
			didSet {
				if let cell = controller?.treeController?.cell(for: self) {
					configure(cell: cell)
				}
				controller?.treeController?.deselectCell(for: self, animated: true)
			}
		}
		
		var prototype: Prototype? {
			return Prototype.TreeHeaderCell.default
		}
		
		var expandIdentifier: CustomStringConvertible?
		var name: String {
			return sectionInfo.name.uppercased()
		}
		
		func configure(cell: UITableViewCell) {
			guard let cell = cell as? TreeHeaderCell else {return}
			
			cell.titleLabel?.text = name
			cell.expandIconView?.image = isExpanded ? #imageLiteral(resourceName: "collapse") : #imageLiteral(resourceName: "expand")
		}
		
	}
}

