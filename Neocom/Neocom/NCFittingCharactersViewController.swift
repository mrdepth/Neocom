//
//  NCFittingCharactersViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFittingCharactersViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	var pilot: NCFittingCharacter?
	var completionHandler: ((NCFittingCharactersViewController, URL) -> Void)!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.clearsSelectionOnViewWillAppear = false
		tableView.register([Prototype.NCFittingCharacterTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default
		                    ])
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		let accounts: [NCAccount]? = NCStorage.sharedStorage?.viewContext.fetch("Account", sortedBy: [NSSortDescriptor(key: "characterName", ascending: true)])
		
		let accountsRows = accounts?.map({NCFittingCharacterRow(account: $0)})
		let levelsRows = [0,1,2,3,4,5].map({NCFittingCharacterRow(level: $0)})
		var sections = [TreeNode]()
		
		sections.append(DefaultTreeSection(nodeIdentifier: "Accounts", title: NSLocalizedString("Accounts", comment: "").uppercased(), children: accountsRows))

		sections.append(DefaultTreeSection(nodeIdentifier: "Predefined", title: NSLocalizedString("Predefined", comment: "").uppercased(), children: levelsRows))

		

		let root = TreeNode()
		root.children = sections
		self.treeController.rootNode = root
		
		self.pilot?.engine?.performBlockAndWait {
			if let url = self.pilot?.url {
				let selected = accountsRows?.first (where: { $0.url == url }) ?? levelsRows.first (where: { $0.url == url })
				
				if let selected = selected {
					self.treeController.selectCell(for: selected, animated: false, scrollPosition: .bottom)
				}
			}
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let node = node as? NCFittingCharacterRow, let url = node.url {
			self.completionHandler(self, url)
		}
	}
}
