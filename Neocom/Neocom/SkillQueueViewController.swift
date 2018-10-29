//
//  SkillQueueViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 19/10/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class SkillQueueViewController: TreeViewController<SkillQueuePresenter, Void>, TreeView {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.rightBarButtonItem = editButtonItem
	}
	
	override func treeController<T>(_ treeController: TreeController, editingStyleFor item: T) -> UITableViewCell.EditingStyle where T : TreeItem {
		return presenter.editingStyle(for: item)
	}
	
	override func treeController<T>(_ treeController: TreeController, canEdit item: T) -> Bool where T : TreeItem {
		return presenter.canEdit(item)
	}
	
	override func treeController<T>(_ treeController: TreeController, commit editingStyle: UITableViewCell.EditingStyle, for item: T) where T : TreeItem {
		presenter.commit(editingStyle: editingStyle, for: item)
	}
	
}
