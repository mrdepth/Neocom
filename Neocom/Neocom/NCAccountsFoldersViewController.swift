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

class NCAccountsFolderRow: NCFetchedResultsObjectNode<NCAccountsFolder> {
	
	required init(object: NCAccountsFolder) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.noImage.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = object.name?.isEmpty == false ? object.name : NSLocalizedString("Unnamed", comment: "")
	}
}

class NCAccountsNoFolder: TreeRow {
	init() {
		super.init(prototype: Prototype.NCDefaultTableViewCell.noImage)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = NSLocalizedString("Default", comment: "")
	}
	
	override var hashValue: Int {
		return 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object is NCAccountsNoFolder)
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
		else if node is NCAccountsNoFolder {
			guard let picker = navigationController as? NCAccountsFolderPickerViewController else {return}
			picker.completionHandler?(picker, nil)
		}
		else {
			guard let row = node as? NCAccountsFolderRow else {return}
			if isEditing {
				performRename(folder: row.object)
			}
			else {
				guard let picker = navigationController as? NCAccountsFolderPickerViewController else {return}
				picker.completionHandler?(picker, row.object)
			}
		}
	}

	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCAccountsFolderRow else {return nil}
		let folder = node.object
		return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { _,_  in
			folder.managedObjectContext?.delete(folder)
			try? folder.managedObjectContext?.save()
		}),
		        UITableViewRowAction(style: .normal, title: NSLocalizedString("Rename", comment: ""), handler: { [weak self] (_,_) in
					self?.performRename(folder: folder)
				})]
	}
	
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		guard let context = NCStorage.sharedStorage?.viewContext else {return}
		
		var sections = [TreeNode]()
		sections.append(NCAccountsNoFolder())
		
		let request = NSFetchRequest<NCAccountsFolder>(entityName: "AccountsFolder")
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		let result = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		sections.append(FetchedResultsNode(resultsController: result, objectNode: NCAccountsFolderRow.self))

		let row = NCActionRow(title: NSLocalizedString("New Folder", comment: "").uppercased())
		
		sections.append(DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, children: [row]))
		self.treeController?.content = RootNode(sections)
		completionHandler()
	}
	
	private func performRename(folder: NCAccountsFolder) {
		let controller = UIAlertController(title: NSLocalizedString("Rename", comment: ""), message: nil, preferredStyle: .alert)
		
		var textField: UITextField?
		
		controller.addTextField(configurationHandler: {
			textField = $0
			textField?.text = folder.name
			textField?.clearButtonMode = .always
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
			if textField?.text?.isEmpty == false && folder.name != textField?.text {
				folder.name = textField?.text
				if folder.managedObjectContext?.hasChanges == true {
					try? folder.managedObjectContext?.save()
				}
			}
		}))
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		
		self.present(controller, animated: true, completion: nil)
	}
}
