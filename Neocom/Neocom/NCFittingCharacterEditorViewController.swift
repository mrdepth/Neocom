//
//  NCFittingCharacterEditorViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 06.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFittingCharacterEditorViewController: UITableViewController, TreeControllerDelegate, UITextFieldDelegate {
	@IBOutlet var treeController: TreeController!
	
	var character: NCFitCharacter?
	var skills: [Int:Int]?
	
	lazy private var managedObjectContext: NSManagedObjectContext? = {
		guard let parentContext = NCStorage.sharedStorage?.viewContext else {return nil}
		let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.parent = parentContext
		return context
	}()
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		self.skills = character?.skills ?? [:]
		let name = character?.name
		let skills = self.skills

		NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
			let request = NSFetchRequest<NSDictionary>(entityName: "InvType")
			let entity = NSEntityDescription.entity(forEntityName: "InvType", in: managedObjectContext)!
			
			request.sortDescriptors = [NSSortDescriptor(key: "group.groupName", ascending: true), NSSortDescriptor(key: "typeName", ascending: true)]
			request.predicate = NSPredicate(format: "published == TRUE AND group.category.categoryID == %d", NCDBCategoryID.skill.rawValue)
			request.resultType = .dictionaryResultType
			let properties = entity.propertiesByName
			request.propertiesToFetch = [
				properties["typeName"]!,
				properties["typeID"]!,
				NSExpressionDescription(name: "groupName", resultType: .stringAttributeType, expression: NSExpression(forKeyPath: "group.groupName"))
			]
			
			
			let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "groupName", cacheName: nil)
			try? controller.performFetch()
			
			var sections = [TreeNode]()
			sections.append(NCTextFieldRow(prototype: Prototype.NCTextFieldTableViewCell.default, text: name, placeholder: NSLocalizedString("Character Name", comment: "")))
			sections.append(FetchedResultsNode(resultsController: controller, sectionNode: NCDefaultFetchedResultsSectionNode<NSDictionary>.self, objectNode: NCSkillEditRow.self))
			
			let root = TreeNode()
			root.children = sections
			
			for section in root.children.last?.children ?? [] {
				for row in section.children {
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
	
	override func viewWillDisappear(_ animated: Bool) {
		view.endEditing(true)
		super.viewWillDisappear(animated)
		for section in self.treeController.content?.children.last?.children ?? [] {
			for row in section.children {
				guard let row = row as? NCSkillEditRow else {continue}
				skills?[row.typeID] = row.level
			}
		}
		character?.skills = skills
		if character?.managedObjectContext?.hasChanges == true {
			try? character?.managedObjectContext?.save()
		}
	}
	
	@IBAction func onRename(_ sender: Any) {
		view.endEditing(true)
	}
	
	@IBAction func didEndEditing(_ sender: UITextField) {
		character?.name = sender.text
	}
	
	//MARK: - UITextFieldDelegate
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.endEditing(true)
		return true
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
	}
}
