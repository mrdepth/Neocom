//
//  MainViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class MainViewController: UITableViewController, TreeView {
	lazy var presenter: MainPresenter! = MainPresenter(view: self)
	lazy var treeController: TreeController! = TreeController()
	
}

class MainAPIItem<T: Codable>: TreeRowItem<TreeDefaultItemContent> {
	var value: CachedValue<TreeDefaultItemContent>
	weak var treeController: TreeController?
	
	init(value: CachedValue<TreeDefaultItemContent>, treeController: TreeController) {
		self.value = value
		self.treeController = treeController
		super.init(content: value.value)
		self.value.observer?.handler = { [weak self] _ in
			guard let strongSelf = self else {return}
			treeController.reloadRow(for: strongSelf, with: .fade)
		}
	}
}
