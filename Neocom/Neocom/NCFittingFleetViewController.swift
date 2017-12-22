//
//  NCFittingFleetViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData
import Dgmpp

class NCFittingFleetViewController: UITableViewController, TreeControllerDelegate, NCFittingEditorPage {
	@IBOutlet weak var treeController: TreeController!
	
	private var observer: NotificationObserver?
	
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
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingFleetDidUpdate, object: fleet, queue: nil) { [weak self] (note) in
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
			route.perform(source: self, sender: treeController.cell(for: node))
			let active = fleet?.active
			if let node = treeController.content?.children.first(where: {($0 as? NCFleetMemberRow)?.pilot == active}) {
				treeController.selectCell(for: node, animated: true, scrollPosition: .none)
			}
		}
		else if let node = node as? NCFleetMemberRow, let fleet = fleet {
			if fleet.active == node.pilot {
				Router.Fitting.Actions(fleet: fleet).perform(source: self, sender: treeController.cell(for: node))
//				parent?.performSegue(withIdentifier: "NCFittingActionsViewController", sender: treeController.cell(for: node))
			}
			else {
				fleet.active = node.pilot
			}
		}
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let route = (node as? TreeRow)?.accessoryButtonRoute else {return}
		
		route.perform(source: self, sender: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCFleetMemberRow else {return nil}
		guard let fleet = fleet else {return nil}
		guard fleet.pilots.count > 1 else {return nil}
		
		let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (_, _) in
			fleet.remove(pilot: node.pilot)
		}
		
		return [deleteAction]
	}
	
	//MARK: - Private
	
	private func reload() {
		guard let fleet = self.fleet else {return}
		let route = Router.Fitting.FleetMemberPicker(fleet: fleet, completionHandler: { controller in
//			_ = controller.navigationController?.popViewController(animated: true)
			controller.dismiss(animated: true, completion: nil)
		})
		

		if fleet.pilots.count == 1 {
			let row = NCActionRow(title: NSLocalizedString("Create Fleet", comment: "").uppercased(), route: route)
			self.treeController.content?.children = [row]
		}
		else {
//			engine?.perform({
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
//			})
		}
	}
}
