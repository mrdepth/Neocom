//
//  NCFittingFleetMemberPickerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import Dgmpp

class NCFittingFleetMemberPickerViewController: NCTreeViewController {
	
	var completionHandler: ((NCFittingFleetMemberPickerViewController) -> Void)!
	var fleet: NCFittingFleet?

	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default])

	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		defer {completionHandler()}
		
		guard let fleet = fleet else {return}
		
		var sections = [TreeNode]()
		
		sections.append(DefaultTreeRow(image: #imageLiteral(resourceName: "fitting"), title: NSLocalizedString("New Ship Fit", comment: ""), accessoryType: .disclosureIndicator, route: Router.Database.TypePicker(category: NCDBDgmppItemCategory.category(categoryID: .ship)!, completionHandler: {[weak self] (controller, type) in
			guard let strongSelf = self else {return}
			strongSelf.dismiss(animated: true)
			
			let typeID = Int(type.typeID)
//			engine.perform {
				try? fleet.append(typeID: typeID)
				DispatchQueue.main.async {
					strongSelf.completionHandler(strongSelf)
				}
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: fleet)
//			}
			
		})))
		
		let context = NCStorage.sharedStorage?.viewContext
		let filter = fleet.pilots.flatMap { (_, objectID) -> NCLoadout? in
			guard let objectID = objectID else {return nil}
			return context?.object(with: objectID) as? NCLoadout
		}
		let predicate = filter.count > 0 ? NSPredicate(format: "NONE SELF IN %@", filter) : nil
		
		
		sections.append(NCLoadoutsSection(categoryID: .ship, filter: predicate))
		if self.treeController?.content == nil {
			self.treeController?.content = TreeNode()
		}
		self.treeController?.content?.children = sections
		
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)

		if let node = node as? NCLoadoutRow {
			guard let fleet = fleet else {return}

			NCStorage.sharedStorage?.performBackgroundTask({ (managedObjectContext) in
				guard let loadout = (try? managedObjectContext.existingObject(with: node.loadoutID)) as? NCLoadout else {return}
//				engine.performBlockAndWait {
					try? fleet.append(loadout: loadout)
					DispatchQueue.main.async {
						self.completionHandler(self)
					}
				NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: fleet)
//				}
			})
		}
	}
	
}
