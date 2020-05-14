//
//  NCFittingDronesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 06.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData
import Dgmpp

class NCFittingDroneRow: TreeRow {
	lazy var type: NCDBInvType? = {
		return self.drones.first?.type
	}()
	
	let drones: [DGMDrone]

	init(drones: [DGMDrone]) {
		self.drones = drones
		super.init(prototype: Prototype.NCFittingDroneTableViewCell.default)
	}
	
	var needsUpdate: Bool = true
	var subtitle: NSAttributedString?
	
	override func configure(cell: UITableViewCell) {
		let drone = drones.first
		guard let cell = cell as? NCFittingDroneTableViewCell else {return}
		cell.object = drones
		
		if drones.count > 1 {
			cell.titleLabel?.attributedText = (type?.typeName ?? "") + " " + "x\(drones.count)" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
		}
		else {
			cell.titleLabel?.text = type?.typeName
		}
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		
		let isActive = drone?.isActive == true
		let isKamikaze = drone?.isKamikaze == true
		let hasTarget = drone?.target != nil
		
		cell.stateView?.image =  (isActive && isKamikaze) ? #imageLiteral(resourceName: "overheated") : isActive ? #imageLiteral(resourceName: "active") : #imageLiteral(resourceName: "offline")
		cell.subtitleLabel?.attributedText = subtitle
		cell.targetIconView.image = hasTarget ? #imageLiteral(resourceName: "targets") : nil
		
		if needsUpdate {
			let font = cell.subtitleLabel!.font!
			
			guard let drone = drone else {return}
			
			let string = NSMutableAttributedString()
			
			let optimal = drone.optimal
			let falloff = drone.falloff
			let velocity = drone.velocity * DGMSeconds(1)
			
			if optimal > 0 {
				let s: NSAttributedString
				let attr = [NSAttributedStringKey.foregroundColor: UIColor.caption]
				let image = NSAttributedString(image: #imageLiteral(resourceName: "targetingRange"), font: font)
				if falloff > 0 {
					s = image + " \(NSLocalizedString("optimal + falloff", comment: "")): " + (NCUnitFormatter.localizedString(from: optimal, unit: .meter, style: .full) + " + " + NCUnitFormatter.localizedString(from: falloff, unit: .meter, style: .full)) * attr
				}
				else {
					s =  image + "\(NSLocalizedString("optimal", comment: "")): " + NCUnitFormatter.localizedString(from: optimal, unit: .meter, style: .full) * attr
				}
				string.appendLine(s)
			}
			if velocity > 0.1 {
				let s = NSAttributedString(image: #imageLiteral(resourceName: "velocity"), font: font) + " \(NSLocalizedString("velocity", comment: "")): " + NCUnitFormatter.localizedString(from: velocity, unit: .meterPerSecond, style: .full) * [NSAttributedStringKey.foregroundColor: UIColor.caption]
				string.appendLine(s)
			}
			
			needsUpdate = false
			subtitle = string

		}
		cell.subtitleLabel?.attributedText = subtitle
	}
	
	override var hash: Int {
		return drones.first?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingDroneRow)?.hashValue == hashValue
	}
}

class NCFittingDroneSection: TreeSection {
	let squadron: DGMDrone.Squadron
	let used: Int
	let limit: Int
	
	init(squadron: DGMDrone.Squadron, ship: DGMShip, children: [NCFittingDroneRow]) {
		self.squadron = squadron
		used = ship.usedDroneSquadron(squadron)
		limit = ship.totalDroneSquadron(squadron)
		super.init(prototype: Prototype.NCHeaderTableViewCell.default)
		self.children = children
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.iconView?.image = #imageLiteral(resourceName: "drone")
		if squadron == .none {
			cell.titleLabel?.text = squadron.title?.uppercased()
		}
		else {
			cell.titleLabel?.attributedText = (squadron.title?.uppercased() ?? "") + " \(used)/\(limit)" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
		}
	}
	
	override var hash: Int {
		return squadron.rawValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingDroneSection)?.hashValue == hashValue
	}
	
}


class NCFittingDronesViewController: UIViewController, TreeControllerDelegate, NCFittingEditorPage {
	@IBOutlet weak var treeController: TreeController!
	@IBOutlet weak var tableView: UITableView!

	@IBOutlet weak var droneBayLabel: NCResourceLabel!
	@IBOutlet weak var droneBandwidthLabel: NCResourceLabel!
	@IBOutlet weak var dronesCountLabel: UILabel!
	
	private var observer: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCActionTableViewCell.default,
		                    Prototype.NCFittingDroneTableViewCell.default
			])

		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		droneBandwidthLabel.unit = .megaBitsPerSecond
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

			let category = NCDBDgmppItemCategory.category(categoryID: .drone)
			
			typePickerViewController.category = category
			typePickerViewController.completionHandler = { [weak typePickerViewController, weak self] (_, type) in
				let typeID = Int(type.typeID)
				let tag = (ship.drones.compactMap({$0.squadron == .none ? $0.squadronTag : nil}).max() ?? -1) + 1
				
				do {
					for _ in 0..<5 {
						let drone = try DGMDrone(typeID: typeID)
						try ship.add(drone, squadronTag: tag)
					}
					NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
				}
				catch {
				}
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
		guard let pilot = fleet?.active else {return}
		guard let ship = pilot.ship else {return}
		
		
		self.droneBayLabel.value = ship.usedDroneBay
		self.droneBayLabel.maximumValue = ship.totalDroneBay
		self.droneBandwidthLabel.value = ship.usedDroneBandwidth
		self.droneBandwidthLabel.maximumValue = ship.totalDroneBandwidth
		
		let droneSquadron = (ship.usedDroneSquadron(.none), ship.totalDroneSquadron(.none))
		self.dronesCountLabel.text = "\(droneSquadron.0)/\(droneSquadron.1)"
		self.dronesCountLabel.textColor = droneSquadron.0 > droneSquadron.1 ? .red : .white
	}
	
	private func reload() {
		guard let pilot = fleet?.active else {return}
		guard let ship = pilot.ship else {return}

		var rows: [TreeNode] = ship.drones.filter{ $0.squadron == .none }
			.map { i -> (Int, String, Int, DGMDrone) in
				return (i.squadronTag, i.type?.typeName ?? "", i.isActive ? 0 : 1, i)
			}
			.sorted {$0 < $1}
			.group { ($0.0, $0.1, $0.2) == ($1.0, $1.1, $1.2) }
			.map {NCFittingDroneRow(drones: $0.map{$0.3})}
		
		rows.append(NCActionRow(title: NSLocalizedString("Add Drone", comment: "").uppercased()))
		treeController.content?.children = rows
		update()
		needsReload = false
	}

}
