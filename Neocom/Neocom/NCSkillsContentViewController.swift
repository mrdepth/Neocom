//
//  NCSkillsContentViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCSkillsContentViewController: UITableViewController, TreeControllerDelegate {
	
	@IBOutlet weak var treeController: TreeController?
	
	var content: [TreeSection]? {
		didSet {
			treeController?.content?.children = content ?? []
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.delegate = treeController
		tableView.dataSource = treeController
		
		tableView.register([
			Prototype.NCHeaderTableViewCell.default,
			Prototype.NCSkillTableViewCell.compact
			]
		)

		treeController?.delegate = self

		let root = TreeNode()
		root.children = content ?? []
		treeController?.content = root
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
	
	
	//MARK: TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let route = (node as? TreeNodeRoutable)?.route {
			route.perform(source: self, view: treeController.cell(for: node))
		}
	}
	
}
