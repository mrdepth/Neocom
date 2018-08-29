//
//  AccountsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class AccountsViewController: UITableViewController, TreeView {
	lazy var presenter: AccountsPresenter! = AccountsPresenter(view: self)
	lazy var treeController: TreeController! = TreeController()
	
}
