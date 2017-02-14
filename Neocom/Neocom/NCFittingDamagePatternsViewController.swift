//
//  NCFittingDamagePatternsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFittingDamagePatternInfoRow: NCFittingDamagePatternRow {
	let name: String
	init(damagePattern: NCFittingDamage, name: String) {
		self.name = name
		super.init(damagePattern: damagePattern)
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDamageTypeTableViewCell else {return}
		cell.titleLabel?.text = name
	}

}

class NCFittingDamagePatternsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	var category: NCDBDgmppItemCategory?
	var completionHandler: ((NCDBInvType) -> Void)!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		let predefined = NSArray(contentsOf: Bundle.main.url(forResource: "damagePatterns", withExtension: "plist")!)?.flatMap { item -> NCFittingDamagePatternInfoRow? in
			guard let item = item as? [String: Any] else {return nil}
			guard let name = item["name"] as? String else {return nil}
			guard let em = item["em"] as? Double else {return nil}
			guard let thermal = item["thermal"] as? Double else {return nil}
			guard let kinetic = item["kinetic"] as? Double else {return nil}
			guard let explosive = item["explosive"] as? Double else {return nil}
			let vector = NCFittingDamage(em: em, thermal: thermal, kinetic: kinetic, explosive: explosive)
			return NCFittingDamagePatternInfoRow(damagePattern: vector, name: name)
		}
		
		var sections = [TreeNode]()
		
		sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Predefined", title: NSLocalizedString("Predefined", comment: "").uppercased(), children: predefined!))
		
		let root = TreeNode()
		root.children = sections
		self.treeController.rootNode = root
		
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? NCFittingAreaEffectRow, let type = node.type else {return}
		completionHandler(type)
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		performSegue(withIdentifier: "NCDatabaseTypeInfoViewController", sender: treeController.cell(for: node))
	}
	
	//MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCDatabaseTypeInfoViewController"?:
			guard let controller = segue.destination as? NCDatabaseTypeInfoViewController,
				let cell = sender as? NCTableViewCell,
				let type = cell.object as? NCDBInvType else {
					return
			}
			controller.type = type
		default:
			break
		}
	}
}
