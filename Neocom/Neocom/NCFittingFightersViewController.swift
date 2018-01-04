//
//  NCFittingFightersViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 10.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData
import Dgmpp

class NCFittingFightersViewController: UIViewController, TreeControllerDelegate, NCFittingEditorPage {
	@IBOutlet weak var treeController: TreeController!
	@IBOutlet weak var tableView: UITableView!
	
	@IBOutlet weak var droneBayLabel: NCResourceLabel!
	@IBOutlet weak var dronesCountLabel: UILabel!
	
	private var observer: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCActionTableViewCell.default,
		                    Prototype.NCFittingDroneTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default
			])
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		droneBayLabel.unit = .cubicMeter
	}
	
	private var needsReload = true

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if self.treeController.content == nil {
			self.treeController.content = TreeNode()
			DispatchQueue.main.async {
				self.reload()
			}
		}
		else if needsReload {
			DispatchQueue.main.async {
				self.reload()
			}
		}

		if observer == nil {
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingFleetDidUpdate, object: fleet, queue: nil) { [weak self] (note) in
				guard self?.view.window != nil else {
					self?.needsReload = true
					return
				}
				self?.reload()
			}
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		treeController.deselectCell(for: node, animated: true)
		if let node = node as? NCFittingDroneRow {
			guard let fleet = fleet else {return}
			Router.Fitting.DroneActions(node.drones, fleet: fleet).perform(source: self, sender: treeController.cell(for: node))
		}
		else if node is NCActionRow {
			guard let pilot = fleet?.active else {return}
			guard let ship = pilot.ship else {return}
			guard let typePickerViewController = typePickerViewController else {return}

			let category = NCDBDgmppItemCategory.category(categoryID: .drone, subcategory:  NCDBCategoryID.fighter.rawValue)
			
			typePickerViewController.category = category
			typePickerViewController.completionHandler = { [weak typePickerViewController, weak self] (_, type) in
				let typeID = Int(type.typeID)
				let tag = -1
				
				do {
					let drone = try DGMDrone(typeID: typeID)
					try ship.add(drone, squadronTag: tag)
					for _ in 1..<drone.squadronSize {
						try ship.add(DGMDrone(typeID: typeID), squadronTag: tag)
					}
					NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
				}
				catch {
				}
				typePickerViewController?.dismiss(animated: true)
				if self?.editorViewController?.traitCollection.horizontalSizeClass == .compact || self?.traitCollection.userInterfaceIdiom == .phone {
					typePickerViewController?.dismiss(animated: true)
				}

			}
			Route(kind: .popover, viewController: typePickerViewController).perform(source: self, sender: treeController.cell(for: node))
			
		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCFittingDroneRow else {return nil}
		
		let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { [weak self] (_, _) in
			let drones = node.drones
			guard let ship = drones.first?.parent as? DGMShip else {return}
			drones.forEach {
				ship.remove($0)
			}
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
		}
		
		return [deleteAction]
	}
	
	//MARK: - Private
	
	private func update() {
		guard let pilot = self.fleet?.active else {return}
		guard let ship = pilot.ship ?? pilot.structure else {return}
		let droneSquadron = (ship.usedFighterLaunchTubes, ship.totalFighterLaunchTubes)
		
		self.droneBayLabel.value = ship.usedFighterHangar
		self.droneBayLabel.maximumValue = ship.totalFighterHangar
		self.dronesCountLabel.text = "\(droneSquadron.0)/\(droneSquadron.1)"
		self.dronesCountLabel.textColor = droneSquadron.0 > droneSquadron.1 ? .red : .white
	}
	
	private func reload() {
		guard let pilot = self.fleet?.active else {return}
		guard let ship = pilot.ship ?? pilot.structure else {return}
		
		var sections: [TreeNode] = ship.drones.map { i -> (Int, Int, String, Int, DGMDrone) in
				return (i.squadron.rawValue, i.squadronTag, i.type?.typeName ?? "", i.isActive ? 0 : 1, i)
			}
			.sorted {$0 < $1}
			.group { $0.0 == $1.0 }
			.map { i -> NCFittingDroneSection in
				let rows = Array(i).group { ($0.1, $0.2, $0.3) == ($1.1, $1.2, $1.3) }
					.map {NCFittingDroneRow(drones: $0.map{$0.4})}
				return NCFittingDroneSection(squadron: DGMDrone.Squadron(rawValue: i.first!.0)!, ship: ship, children: rows)
			}
		
		
		sections.append(NCActionRow(title: NSLocalizedString("Add Drone", comment: "").uppercased()))
		treeController.content?.children = sections
		update()
		needsReload = false
	}
	
}
