//
//  NCFittingAreaEffectsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI

/*class NCFittingAreaEffectRow: TreeRow {
	let objectID: NSManagedObjectID
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.viewContext.object(with: self.objectID) as? NCDBInvType
	}()
	
	init(objectID: NSManagedObjectID) {
		self.objectID = objectID
		super.init(cellIdentifier: "NCDefaultTableViewCell", accessoryButtonSegue: "NCDatabaseTypeInfoViewController")
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.object = type
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.accessoryType = .detailButton
	}
}*/

class NCFittingAreaEffectsViewController: NCTreeViewController {

	var category: NCDBDgmppItemCategory?
	var completionHandler: ((NCFittingAreaEffectsViewController, NCDBInvType?) -> Void)!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCHeaderTableViewCell.default
		                    ])
	}
	
	override func content() -> Future<TreeNode?> {
		guard let managedObjectContext = NCDatabase.sharedDatabase?.viewContext else {return .init(nil)}
		guard let types: [NCDBInvType] = managedObjectContext.fetch("InvType", sortedBy: [NSSortDescriptor(key: "typeName", ascending: true)], where: "group.groupID == 920") else {return .init(nil)}
		
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
			let rows = array.map({NCTypeInfoRow(objectID: $0, managedObjectContext: managedObjectContext, accessoryType: .detailButton)})
			
			return DefaultTreeSection(nodeIdentifier: prefix, title: prefix.uppercased(), children: rows)
		}
		return .init(RootNode(sections))
	}
	
	@IBAction func onClear(_ sender: Any) {
		completionHandler(self, nil)
	}

	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let node = node as? NCTypeInfoRow, let type = node.type else {return}
		completionHandler(self, type)
	}
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		guard let node = node as? NCTypeInfoRow, let type = node.type else {return}
		Router.Database.TypeInfo(type).perform(source: self, sender: treeController.cell(for: node))
	}
		
}
