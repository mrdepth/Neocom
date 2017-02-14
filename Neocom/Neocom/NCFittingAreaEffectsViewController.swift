//
//  NCFittingAreaEffectsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFittingAreaEffectRow: TreeRow {
	let objectID: NSManagedObjectID
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.viewContext.object(with: self.objectID) as? NCDBInvType
	}()
	
	init(objectID: NSManagedObjectID) {
		self.objectID = objectID
		super.init(cellIdentifier: "Cell", accessoryButtonSegue: "NCDatabaseTypeInfoViewController")
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.object = type
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.accessoryType = .detailButton
	}
}

class NCFittingAreaEffectsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	var category: NCDBDgmppItemCategory?
	var completionHandler: ((NCDBInvType) -> Void)!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
			guard let types: [NCDBInvType] = managedObjectContext.fetch("InvType", sortedBy: [NSSortDescriptor(key: "typeName", ascending: true)], where: "group.groupID == 920") else {return}
			
			let prefixes = ["Black Hole Effect Beacon Class",
			 "Cataclysmic Variable Effect Beacon Class",
			 "Magnetar Effect Beacon Class",
			 "Pulsar Effect Beacon Class",
			 "Red Giant Beacon Class",
			 "Wolf Rayet Effect Beacon Class",
			 "Incursion",
			 "Drifter Incursion",
			 ]
			let n = prefixes.count

			var arrays = [[NSManagedObjectID]](repeating: [], count: n + 1)
			
			types: for type in types {
				for (i, prefix) in prefixes.enumerated() {
					if type.typeName?.hasPrefix(prefix) == true {
						arrays[i].append(type.objectID)
						continue types
					}
				}
				arrays[n].append(type.objectID)
			}
			
			let sections = arrays.enumerated().map { (i, array) -> DefaultTreeSection in
				let prefix = i < n ? prefixes[i] : NSLocalizedString("Other", comment: "")
				let rows = array.map({NCFittingAreaEffectRow(objectID: $0)})
				
				return DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: prefix, title: prefix.uppercased(), children: rows)
			}
			
			DispatchQueue.main.async {
				let root = TreeNode()
				root.children = sections
				self.treeController.rootNode = root
			}
		}
		
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? NCFittingAreaEffectRow, let type = node.type else {return}
		completionHandler(type)
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		performSegue(withIdentifier: "NCDatabaseTypeInfoViewController", sender: treeController.cell(for: node))
	}
		
	//MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCDatabaseTypeInfoViewController"?:
			guard let controller = segue.destination as? NCDatabaseTypeInfoViewController,
				let cell = sender as? NCTableViewCell,
				let type = cell.object as? NCDBInvType else {
					return
			}
			controller.type = type
		default:
			break
		}
	}
}
