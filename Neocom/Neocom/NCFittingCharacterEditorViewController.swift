//
//  NCFittingCharacterEditorViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 06.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFittingCharacterEditorViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	
	var character: NCFitCharacter?
	
	lazy private var managedObjectContext: NSManagedObjectContext? = {
		guard let parentContext = NCStorage.sharedStorage?.viewContext else {return nil}
		let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.parent = parentContext
		return context
	}()
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
//		treeController.disableTransitions = true
		
		let skills = character?.skills

		NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
			let request = NSFetchRequest<NSDictionary>(entityName: "InvType")
			let entity = NSEntityDescription.entity(forEntityName: "InvType", in: managedObjectContext)!
			
			request.sortDescriptors = [NSSortDescriptor(key: "group.groupName", ascending: true), NSSortDescriptor(key: "typeName", ascending: true)]
			request.predicate = NSPredicate(format: "published == TRUE")
			request.resultType = .dictionaryResultType
			let properties = entity.propertiesByName
			request.propertiesToFetch = [
				properties["typeName"]!,
				properties["typeID"]!,
				NSExpressionDescription(name: "groupName", resultType: .stringAttributeType, expression: NSExpression(forKeyPath: "group.groupName"))
			]
			
			
			let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "groupName", cacheName: nil)
			try? controller.performFetch()
			
			let root = FetchedResultsNode(resultsController: controller, sectionNode: NCDefaultFetchedResultsSectionNode<NSDictionary>.self, objectNode: NCSkillEditRow.self)
			
			for section in root.children ?? [] {
				for row in section.children ?? [] {
					guard let row = row as? NCSkillEditRow else {continue}
					row.level = skills?[row.typeID] ?? 0
				}
			}

			DispatchQueue.main.async {
				self.treeController.content = root
			}
			
		}
		
		tableView.register([Prototype.NCHeaderTableViewCell.default])
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
	}
}
