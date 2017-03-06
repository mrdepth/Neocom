//
//  NCFittingCharactersViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFittingCharactersViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
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
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		var sections = [TreeNode]()

		if let context = managedObjectContext {
			sections.append(NCAccountCharactersSection(managedObjectContext: context))
			sections.append(NCCustomCharactersSection(managedObjectContext: context))
		}
		
		
		let levelsRows = [0,1,2,3,4,5].map({NCPredefinedCharacterRow(level: $0)})
		
		sections.append(DefaultTreeSection(nodeIdentifier: "Predefined", title: NSLocalizedString("Predefined", comment: "").uppercased(), children: levelsRows))

		let root = TreeNode()
		root.children = sections
		self.treeController.rootNode = root
		
		self.pilot?.engine?.performBlockAndWait {
//			if let url = self.pilot?.url {
//				let selected = accountsRows?.first (where: { $0.url == url }) ?? levelsRows.first (where: { $0.url == url })
//				
//				if let selected = selected {
//					self.treeController.selectCell(for: selected, animated: false, scrollPosition: .bottom)
//				}
//			}
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if node is NCActionRow {
			guard let context = managedObjectContext else {return}
			let character = NCFitCharacter(entity: NSEntityDescription.entity(forEntityName: "FitCharacter", in: context)!, insertInto: context)
			
			Router.Fitting.CharacterEditor(character: character).perform(source: self, view: treeController.cell(for: node))
			
//			try? context.save()
		}
//		if let node = node as? NCFittingCharacterRow, let url = node.url {
//			self.completionHandler(self, url)
//		}
	}
}
