//
//  NCAccountsFoldersViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import CloudData

class NCAccountsFolderRow: FetchedResultsObjectNode<NCAccountsFolder> {
	
	required init(object: NCAccountsFolder) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.noImage.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = object.name?.isEmpty == false ? object.name : NSLocalizedString("Unnamed", comment: "")
	}
}

class NCAccountsFoldersViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.noImage,
		                    Prototype.NCActionTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.empty])
		
		navigationItem.rightBarButtonItem = editButtonItem
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		if node is NCActionRow {
			guard let context = NCStorage.sharedStorage?.viewContext else {return}
			
			let controller = UIAlertController(title: NSLocalizedString("Enter Folder Name", comment: ""), message: nil, preferredStyle: .alert)
			
			var textField: UITextField?
			
			controller.addTextField(configurationHandler: {
				textField = $0
			})
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Add Folder", comment: ""), style: .default, handler: { (action) in
				let folder = NCAccountsFolder(entity: NSEntityDescription.entity(forEntityName: "AccountsFolder", in: context)!, insertInto: context)
				folder.name = textField?.text
				if context.hasChanges {
					try? context.save()
				}
			}))
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
			
			self.present(controller, animated: true, completion: nil)

		}
		else {
			guard let row = node as? NCAccountsFolderRow else {return}
			if isEditing {
				let controller = UIAlertController(title: NSLocalizedString("Rename", comment: ""), message: nil, preferredStyle: .alert)
				
				var textField: UITextField?
				
				controller.addTextField(configurationHandler: {
					textField = $0
					textField?.text = row.object.name
					textField?.clearButtonMode = .always
				})
				
				controller.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
					if textField?.text?.characters.count ?? 0 > 0 && row.object.name != textField?.text {
						row.object.name = textField?.text
						if row.object.managedObjectContext?.hasChanges == true {
							try? row.object.managedObjectContext?.save()
						}
					}
				}))
				
				controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
				
				self.present(controller, animated: true, completion: nil)
			}
			else {
				guard let picker = navigationController as? NCAccountsFolderPickerViewController else {return}
				picker.completionHandler(picker, row.object)
			}
		}
	}

	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCLoadoutRow else {return nil}
		
		let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { _ in
			guard let context = NCStorage.sharedStorage?.viewContext else {return}
			guard let loadout = (try? context.existingObject(with: node.loadoutID)) as? NCLoadout else {return}
			context.delete(loadout)
			if context.hasChanges {
				try? context.save()
			}
		}
		
		return [deleteAction]
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		guard let context = NCStorage.sharedStorage?.viewContext else {return}
		
		var sections = [TreeNode]()
		
		let request = NSFetchRequest<NCAccountsFolder>(entityName: "AccountsFolder")
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		let result = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		sections.append(FetchedResultsNode(resultsController: result, objectNode: NCAccountsFolderRow.self))

		let row = NCActionRow(title: NSLocalizedString("New Folder", comment: "").uppercased())
		
		sections.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, children: [row]))
		self.treeController?.content = RootNode(sections)
		completionHandler()
	}
}
