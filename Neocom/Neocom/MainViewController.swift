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

//class MainAPIItem<T: Codable>: TreeRowItem<TreeDefaultItemContent> {
//	var value: CachedValue<T>
//	init(value: CachedValue<T>) {
//		self.value = value
//		super.init(content: <#T##TreeDefaultItemContent#>, children: <#T##[TreeItemNull]?#>)
//	}
//}
