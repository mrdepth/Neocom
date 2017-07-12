//
//  NCFittingStructuresViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import CloudData

class NCFittingStructuresViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default])
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if treeController.content == nil {
			self.treeController.content = TreeNode()
			reload()
		}
	}
	
	//MARK: - TreeControllerDelegate
	
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
	
	//MARK: - Private
	
	private func reload() {
		var sections = [TreeNode]()
		
		
		sections.append(DefaultTreeRow(image: #imageLiteral(resourceName: "station"), title: NSLocalizedString("New Structure Fit", comment: ""), accessoryType: .disclosureIndicator, route: Router.Database.TypePicker(category: NCDBDgmppItemCategory.category(categoryID: .structure)!, completionHandler: {[weak self] (controller, type) in
			guard let strongSelf = self else {return}
			strongSelf.dismiss(animated: true)
			
			Router.Fitting.Editor(typeID: Int(type.typeID)).perform(source: strongSelf)

			/*let engine = NCFittingEngine()
			let typeID = Int(type.typeID)
			engine.perform {
				let fleet = NCFittingFleet(typeID: typeID, engine: engine)
				DispatchQueue.main.async {
					if let account = NCAccount.current {
						fleet.active?.setSkills(from: account) { [weak self]  _ in
							guard let strongSelf = self else {return}
							Router.Fitting.Editor(fleet: fleet, engine: engine).perform(source: strongSelf)
						}
					}
					else {
						fleet.active?.setSkills(level: 5) { [weak self] _ in
							guard let strongSelf = self else {return}
							Router.Fitting.Editor(fleet: fleet, engine: engine).perform(source: strongSelf)
						}
					}
				}
			}*/
			
		})))
		
		sections.append(NCLoadoutsSection(categoryID: .structure))
		self.treeController.content?.children = sections
	}
}
