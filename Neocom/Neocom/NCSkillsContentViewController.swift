//
//  NCSkillsContentViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCSkillsContentViewController: NCTreeViewController {
	
	var content: [TreeSection]? {
		didSet {
			treeController?.content?.children = content ?? []
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([
			Prototype.NCHeaderTableViewCell.default,
			Prototype.NCSkillTableViewCell.default
			]
		)

		let root = TreeNode()
		root.children = content ?? []
		treeController?.content = root
	}
	
}
