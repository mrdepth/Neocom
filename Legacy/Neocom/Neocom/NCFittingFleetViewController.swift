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
import EVEAPI

class NCFittingFleetViewController: NCTreeViewController, NCFittingEditorPage {
	
	private var observer: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCActionTableViewCell.default,
		                    Prototype.NCFleetMemberTableViewCell.default
			])

	}
	
	private var needsReload = true

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if observer == nil {
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingFleetDidUpdate, object: fleet, queue: nil) { [weak self] (note) in
				guard self?.view.window != nil else {
					self?.needsReload = true
					return
				}
				self?.reload()
			}
		}
		
		let active = fleet?.active
		if let node = treeController?.content?.children.first(where: {($0 as? NCFleetMemberRow)?.pilot == active}) {
			treeController?.selectCell(for: node, animated: true, scrollPosition: .none)
		}

		if needsReload {
			reload()
		}

	}
	
	private let root = TreeNode()
	override func content() -> Future<TreeNode?> {
		guard editorViewController != nil else {return .init(nil)}
		reload()
		return .init(root)
	}

	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
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
			}
			else {
				fleet.active = node.pilot
			}
		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCFleetMemberRow else {return nil}
		guard let fleet = fleet else {return nil}
		guard fleet.pilots.count > 1 else {return nil}
		
		let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (_, _) in
			fleet.remove(pilot: node.pilot)
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: fleet)
		}
		
		return [deleteAction]
	}
	
	//MARK: - Private
	
	private func reload() {
		guard let fleet = self.fleet else {return}
		let route = Router.Fitting.FleetMemberPicker(fleet: fleet, completionHandler: { controller in
			controller.dismiss(animated: true, completion: nil)
		})
		

		if fleet.pilots.count == 1 {
			let row = NCActionRow(title: NSLocalizedString("Create Fleet", comment: "").uppercased(), route: route)
			root.children = [row]
		}
		else {
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
			
			root.children = rows
			if let node = active {
				treeController?.selectCell(for: node, animated: false, scrollPosition: .none)
			}
		}
		needsReload = false
	}
}
