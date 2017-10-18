//
//  NCMailDraftsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 17.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI


class NCMailDraftsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCMailTableViewCell.default])
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		treeController?.content = NCDraftsNode()
		updateBackground()
		completionHandler()
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeControllerDidUpdateContent(_ treeController: TreeController) {
		updateBackground()
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCDraftRow else { return nil}
		return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { _,_  in
			node.object.managedObjectContext?.delete(node.object)
			if node.object.managedObjectContext?.hasChanges == true {
				try? node.object.managedObjectContext?.save()
			}
		})]
	}

	private func updateBackground() {
		tableView.backgroundView = treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: NSLocalizedString("No Messages", comment: ""))
	}

}
