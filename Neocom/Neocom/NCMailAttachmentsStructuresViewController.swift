//
//  NCMailAttachmentsStructuresViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 12.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCMailAttachmentsStructuresViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default])
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func content() -> Future<TreeNode?> {
		return .init(NCLoadoutsSection<NCAttachmentLoadoutRow>(categoryID: .structure))
	}

	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let item = node as? NCLoadoutRow else {return}
		guard let context = NCStorage.sharedStorage?.viewContext else {return}
		guard let loadout = (try? context.existingObject(with: item.loadoutID)) else {return}
		guard let parent = parent as? NCMailAttachmentsViewController else {return}
		parent.completionHandler?(parent, loadout)
	}
	
	func treeControllerDidUpdateContent(_ treeController: TreeController) {
		tableView.backgroundView = treeController.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: ""))
	}

}
