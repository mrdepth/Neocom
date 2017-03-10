//
//  NCFittingFleetViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingFleetViewController: UITableViewController, TreeControllerDelegate {
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
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCActionTableViewCell.default,
		                    Prototype.NCFleetMemberTableViewCell.default
			])

		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if self.treeController.content == nil {
			self.treeController.content = TreeNode()
			reload()
		}
		
		if observer == nil {
			observer = NotificationCenter.default.addObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
		
		let active = fleet?.active
		if let node = treeController.content?.children.first(where: {($0 as? NCFleetMemberRow)?.pilot == active}) {
			treeController.selectCell(for: node, animated: true, scrollPosition: .none)
		}

	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let route = (node as? TreeRow)?.route {
			route.perform(source: self, view: treeController.cell(for: node))
			let active = fleet?.active
			if let node = treeController.content?.children.first(where: {($0 as? NCFleetMemberRow)?.pilot == active}) {
				treeController.selectCell(for: node, animated: true, scrollPosition: .none)
			}
		}
		else if let node = node as? NCFleetMemberRow {
			fleet?.active = node.pilot
		}
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let route = (node as? TreeRow)?.accessoryButtonRoute else {return}
		
		route.perform(source: self, view: treeController.cell(for: node))
	}
	
	//MARK: - Private
	
	private func reload() {
		guard let fleet = self.fleet else {return}
		let route = Router.Fitting.FleetMemberPicker(fleet: fleet, completionHandler: { controller in
			_ = controller.navigationController?.popViewController(animated: true)
		})
		

		if fleet.pilots.count == 1 {
			let row = NCActionRow(title: NSLocalizedString("Create Fleet", comment: "").uppercased(), route: route)
			self.treeController.content?.children = [row]
		}
		else {
			engine?.perform({
				var active: TreeNode?
				
				var rows = [TreeNode]()
				for (pilot, _) in fleet.pilots {
					let row = NCFleetMemberRow(pilot: pilot)
					rows.append(row)
					if fleet.active == pilot {
						active = row
					}
				}
				
				rows.append(NCActionRow(title: NSLocalizedString("Add Pilot", comment: "").uppercased(), route: route))
				
				DispatchQueue.main.async {
					self.treeController.content?.children = rows
					if let node = active {
						self.treeController.selectCell(for: node, animated: false, scrollPosition: .none)
					}
				}
			})
		}
	}
}
