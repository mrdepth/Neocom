//
//  NCFittingCharactersViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFittingCharactersViewController: NCTreeViewController {
	var pilot: NCFittingCharacter?
	var completionHandler: ((NCFittingCharactersViewController, URL) -> Void)!
	
	lazy private var managedObjectContext: NSManagedObjectContext? = {
		guard let parentContext = NCStorage.sharedStorage?.viewContext else {return nil}
		let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.parent = parentContext
		return context
	}()

	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.rightBarButtonItem = editButtonItem
		
		self.clearsSelectionOnViewWillAppear = false
		tableView.register([Prototype.NCFittingCharacterTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCActionTableViewCell.default
		                    ])
		
		var sections = [TreeNode]()

		if let context = managedObjectContext {
			sections.append(NCAccountCharactersSection(managedObjectContext: context))
			sections.append(NCCustomCharactersSection(managedObjectContext: context))
		}
		
		
		let levelsRows = [0,1,2,3,4,5].map({NCPredefinedCharacterRow(level: $0)})
		
		sections.append(DefaultTreeSection(nodeIdentifier: "Predefined", title: NSLocalizedString("Predefined", comment: "").uppercased(), children: levelsRows))

		let root = TreeNode()
		root.children = sections
		self.treeController?.content = root

	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if transitionCoordinator?.viewController(forKey: .to) == self.presentingViewController {
			if let context = managedObjectContext?.parent, context.hasChanges {
				try? context.save()
			}
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		if node is NCActionRow {
			guard let context = managedObjectContext else {return}
			let character = NCFitCharacter(entity: NSEntityDescription.entity(forEntityName: "FitCharacter", in: context)!, insertInto: context)
			character.uuid = UUID().uuidString
			Router.Fitting.CharacterEditor(character: character).perform(source: self, view: treeController.cell(for: node))
		}
		else if let node = node as? NCCustomCharacterRow {
			if isEditing {
				Router.Fitting.CharacterEditor(character: node.object).perform(source: self, view: treeController.cell(for: node))
			}
			else if let url = node.url {
				if let context = managedObjectContext?.parent, context.hasChanges {
					try? context.save()
				}

				self.completionHandler(self, url)
			}
		}
		else if let node = node as? NCPredefinedCharacterRow, let url = node.url {
			self.completionHandler(self, url)
		}
		else if let node = node as? NCAccountCharacterRow, let url = node.url {
			self.completionHandler(self, url)
		}
//		if let node = node as? NCFittingCharacterRow, let url = node.url {
//			self.completionHandler(self, url)
//		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		if let node = node as? NCCustomCharacterRow {
			guard let context = managedObjectContext else {return nil}
			return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { (_, _) in
				context.delete(node.object)
				if context.hasChanges {
					try? context.save()
				}
			})]
		}
		else {
			return nil
		}
	}
}
