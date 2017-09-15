//
//  NCFittingImplantSetViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCImplantSetRow: NCFetchedResultsObjectNode<NCImplantSet> {
	
	required init(object: NCImplantSet) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.default.reuseIdentifier
	}
	
	lazy var subtitle: NSAttributedString? = {
		guard let invTypes = NCDatabase.sharedDatabase?.invTypes else {return nil}
		let font = UIFont.preferredFont(forTextStyle: .footnote)
		
		var ids = self.object.data?.implantIDs ?? []
		ids.append(contentsOf: self.object.data?.boosterIDs ?? [])
		
		
		return ids.flatMap { typeID -> NSAttributedString? in
			guard let type = invTypes[typeID] else {return nil}
			guard let typeName = type.typeName else {return nil}
			if let image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image {
				return NSAttributedString(image: image, font: font) + typeName
			}
			else {
				return NSAttributedString(string: typeName)
			}
			}.reduce((NSAttributedString(), 0), { (a, b) -> (NSAttributedString, Int) in
				let i = a.1
				let a = a.0
				return i == 3 ? (a + "\n" + "...", i + 1) :
						i > 3 ? (a, i + 1) :
						i == 0 ? (b, 1) :
						(a + "\n" + b, i + 1)
			}).0
	}()
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = object.name
		cell.subtitleLabel?.attributedText = (subtitle?.length ?? 0) > 0 ? subtitle : NSAttributedString(string: NSLocalizedString("Empty", comment: ""))
	}
}

class NCImplantSetSection: FetchedResultsNode<NCImplantSet> {
	init(managedObjectContext: NSManagedObjectContext) {
		let request = NSFetchRequest<NCImplantSet>(entityName: "ImplantSet")
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

		super.init(resultsController: results, sectionNode: nil, objectNode: NCImplantSetRow.self)
//		cellIdentifier = Prototype.NCHeaderTableViewCell.empty.reuseIdentifier
	}
}

class NCFittingImplantSetViewController: NCTreeViewController {
	
	var implantSetData: NCImplantSetData?
	var completionHandler: ((NCFittingImplantSetViewController, NCImplantSet) -> Void)?
	
	enum Mode {
		case load
		case save
	}
	
	var mode: Mode = .load
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationItem.rightBarButtonItem = editButtonItem
		
		tableView.register([Prototype.NCActionTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.empty])
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		defer {
			completionHandler()
		}
		
		guard let managedObjectContext = NCStorage.sharedStorage?.viewContext else {return}
		var sections = [TreeNode]()
		if mode == .save {
			let save = NCActionRow(title: NSLocalizedString("Create New Implant Set", comment: "").uppercased())
			sections.append(RootNode([save]))
		}
		
		sections.append(NCImplantSetSection(managedObjectContext: managedObjectContext))
		
		treeController?.content = RootNode(sections)
	}
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		
		if node is NCActionRow {
			guard let implantSetData = implantSetData else {return}
			guard let context = NCStorage.sharedStorage?.viewContext else {return}
			
			let controller = UIAlertController(title: NSLocalizedString("Enter Implant Set Name", comment: ""), message: nil, preferredStyle: .alert)
			
			var textField: UITextField?
			
			controller.addTextField(configurationHandler: {
				textField = $0
				textField?.clearButtonMode = .always
			})
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Create", comment: ""), style: .default, handler: { [weak self] _ in
				let implantSet = NCImplantSet(entity: NSEntityDescription.entity(forEntityName: "ImplantSet", in: context)!, insertInto: context)
				implantSet.data = implantSetData
				implantSet.name = textField?.text
				if context.hasChanges {
					try? context.save()
				}
				
				self?.dismiss(animated: true, completion: nil)
				
			}))
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
			
			self.present(controller, animated: true, completion: nil)
		}
		else if let row = node as? NCImplantSetRow {
			let implantSet = row.object

			if isEditing {
				let controller = UIAlertController(title: NSLocalizedString("Rename", comment: ""), message: nil, preferredStyle: .alert)
				
				var textField: UITextField?
				
				controller.addTextField(configurationHandler: {
					textField = $0
					textField?.text = implantSet.name
					textField?.clearButtonMode = .always
				})
				
				controller.addAction(UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .default, handler: { _ in
					implantSet.name = textField?.text
					if implantSet.managedObjectContext?.hasChanges == true {
						try? implantSet.managedObjectContext?.save()
					}
					
				}))
				
				controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
				present(controller, animated: true, completion: nil)
			}
			else {
				if mode == .save {
					guard let implantSetData = implantSetData else {return}
					
					let controller = UIAlertController(title: nil, message: NSLocalizedString("Are you sure you want to replace this set?", comment: ""), preferredStyle: .alert)
					
					controller.addAction(UIAlertAction(title: NSLocalizedString("Replace", comment: ""), style: .default, handler: { [weak self] _ in
						implantSet.data = implantSetData
						if implantSet.managedObjectContext?.hasChanges == true {
							try? implantSet.managedObjectContext?.save()
						}
						
						self?.dismiss(animated: true, completion: nil)
						
					}))
					
					controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
					
					present(controller, animated: true, completion: nil)
					
				}
				else {
					completionHandler?(self, implantSet)
				}
			}
		}
		
		
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let row = node as? NCImplantSetRow else {return nil}
		let object = row.object
		return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { _,_  in
			object.managedObjectContext?.delete(object)
			if object.managedObjectContext?.hasChanges == true {
				try? object.managedObjectContext?.save()
			}
		}]
	}
}
