//
//  NCFittingStatsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingStatsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet weak var treeController: TreeController!

	var engine: NCFittingEngine? {
		return (parent as? NCFittingEditorViewController)?.engine
	}
	
	var fleet: NCFittingFleet? {
		return (parent as? NCFittingEditorViewController)?.fleet
	}
	
	private var observer: NSObjectProtocol?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if self.treeController.rootNode == nil {
			reload()
		}
		
		if observer == nil {
			observer = NotificationCenter.default.addObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
	}
	
	//MARK: - Private
	
	private func reload() {
		engine?.perform {
			guard let ship = self.fleet?.active?.ship else {return}
			var sections = [TreeNode]()
			
			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Resources", title: NSLocalizedString("Resources", comment: "").uppercased(), children: [NCFittingResourcesRow(ship: ship)]))
			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Resistances", title: NSLocalizedString("Resistances", comment: "").uppercased(), children: [NCResistancesRow(ship: ship)]))
			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Capacitor", title: NSLocalizedString("Capacitor", comment: "").uppercased(), children: [NCFittingCapacitorRow(ship: ship)]))
			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Tank", title: NSLocalizedString("Recharge Rates (HP/s, EHP/s)", comment: "").uppercased(), children: [NCTankRow(ship: ship)]))
			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Firepower", title: NSLocalizedString("Firepower", comment: "").uppercased(), children: [NCFirepowerRow(ship: ship)]))
			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Misc", title: NSLocalizedString("Misc", comment: "").uppercased(), children: [NCFittingMiscRow(ship: ship)]))

			DispatchQueue.main.async {
				if self.treeController.rootNode == nil {
					self.treeController.rootNode = TreeNode()
				}
				self.treeController.rootNode?.children = sections
			}
		}
	}
}
