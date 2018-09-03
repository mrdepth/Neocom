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

protocol FetchedResultsControllerTreeItemProtocol: class {
	var treeController: TreeController? {get}
}

protocol FetchedResultsSectionTreeItemProtocol: class {
	var controller: FetchedResultsControllerTreeItemProtocol? {get}
}

protocol FetchedResultsTreeItem: TreeItem {
	associatedtype Result: NSFetchRequestResult & Equatable
	var content: Result {get}
	var section: FetchedResultsSectionTreeItemProtocol? {get set}
	
	init(_ content: Result, section: FetchedResultsSectionTreeItemProtocol)
}

extension FetchedResultsTreeItem {
	var hashValue: Int {
		return content.hash
	}
	
	var diffIdentifier: Result {
		return content
	}
	
	static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.content == rhs.content
	}

}

extension Tree.Item {
	class FetchedResultsController<Result: NSFetchRequestResult & Equatable, Section: FetchedResultsSection<Item>, Item: FetchedResultsTreeItem>: NSObject, TreeItem, NSFetchedResultsControllerDelegate, FetchedResultsControllerTreeItemProtocol where Item.Result == Result {
		var fetchedResultsController: NSFetchedResultsController<Result>
		weak var treeController: TreeController?
		
		override var hash: Int {
//			return diffIdentifier.hash
			return fetchedResultsController.fetchRequest.hash
		}

		typealias DiffIdentifier = AnyHashable
		var diffIdentifier: AnyHashable
//		var children: [Child]?
		
		lazy var children: [Section]? = {
			try? fetchedResultsController.performFetch()
			return fetchedResultsController.sections?.map {Child($0, controller: self)}
		}()
		
		init<T: Hashable>(_ fetchedResultsController: NSFetchedResultsController<Result>, diffIdentifier: T, treeController: TreeController?) {
			self.fetchedResultsController = fetchedResultsController
			self.diffIdentifier = AnyHashable(diffIdentifier)
			self.treeController = treeController
			super.init()
			fetchedResultsController.delegate = self
		}
		
		convenience init(_ fetchedResultsController: NSFetchedResultsController<Result>, treeController: TreeController?) {
			self.init(fetchedResultsController, diffIdentifier: fetchedResultsController.fetchRequest, treeController: treeController)
		}

		static func == (lhs: Tree.Item.FetchedResultsController<Result, Section, Item>, rhs: Tree.Item.FetchedResultsController<Result, Section, Item>) -> Bool {
			return lhs.fetchedResultsController == rhs.fetchedResultsController
		}
		
		private struct Updates {
			var sectionInsertions = [(Int, NSFetchedResultsSectionInfo)]()
			var sectionDeletions = IndexSet()
			var itemInsertions = [(IndexPath, Any)]()
			var itemDeletions = [IndexPath]()
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
				updates?.itemInsertions.append((newIndexPath!, children![indexPath!.section].children![indexPath!.item]))
			case .update:
				break
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
				
				if var item = i.1 as? Item {
					item.section = section
					section.children!.insert(item, at: i.0.item)
				}
				else if let result = i.1 as? Result {
					let item = Item(result, section: section)
					section.children!.insert(item, at: i.0.item)
				}
			}
			updates = nil
			treeController?.update(contentsOf: self, with: .fade)
		}
	}
	
	class FetchedResultsSection<Item: FetchedResultsTreeItem>: TreeItem, FetchedResultsSectionTreeItemProtocol {
		static func == (lhs: Tree.Item.FetchedResultsSection<Item>, rhs: Tree.Item.FetchedResultsSection<Item>) -> Bool {
			return lhs.sectionInfo.name == rhs.sectionInfo.name
		}
		
		weak var controller: FetchedResultsControllerTreeItemProtocol?
		var sectionInfo: NSFetchedResultsSectionInfo
		
		var hashValue: Int {
			return sectionInfo.name.hashValue
		}

//		var diffIdentifier: String {
//			return sectionInfo.name
//		}
		
//		typealias Child = Item
		lazy var children: [Item]? = sectionInfo.objects?.map{Item($0 as! Item.Result, section: self)}

		
		required init(_ sectionInfo: NSFetchedResultsSectionInfo, controller: FetchedResultsControllerTreeItemProtocol) {
			self.sectionInfo = sectionInfo
			self.controller = controller
		}
	}
	
	class FetchedResultsRow<Result: NSFetchRequestResult & Equatable>: FetchedResultsTreeItem {
		var content: Result
		weak var section: FetchedResultsSectionTreeItemProtocol?
		
		required init(_ content: Result, section: FetchedResultsSectionTreeItemProtocol) {
			self.content = content
			self.section = section
		}
	}
}



