//
//  NCFittingDroneActionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 07.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import CloudData
import Dgmpp
import EVEAPI

class NCFittingDroneInfoRow: NCChargeRow {
	let count: Int
	
	init(type: NCDBInvType, drone: DGMDrone, count: Int, route: Route? = nil) {
		self.count = count
		super.init(type: type, route: route, accessoryButtonRoute: Router.Database.TypeInfo(drone))
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		if count > 0 {
			let title = (type.typeName ?? "") + " x\(count)" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
			if let cell = cell as? NCChargeTableViewCell {
				cell.titleLabel?.attributedText = title
			}
			else if let cell = cell as? NCDefaultTableViewCell{
				cell.titleLabel?.attributedText = title
				cell.accessoryType = .detailButton
			}
			
		}
	}
	
	override var hashValue: Int {
		return type.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingDroneInfoRow)?.hashValue == hashValue
	}
}

class NCFittingDroneStateRow: TreeRow {
	let drones: [DGMDrone]
	let fleet: NCFittingFleet
	let isActive: Bool
	let isKamikaze: Bool
	init(drones: [DGMDrone], fleet: NCFittingFleet) {
		self.drones = drones
		self.fleet = fleet
		isActive = drones.first?.isActive ?? false
		isKamikaze = drones.first?.isKamikaze ?? false
		super.init(prototype: Prototype.NCFittingDroneStateTableViewCell.default)
		
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingDroneStateTableViewCell else {return}
		cell.object = self
		
		cell.segmentedControl?.removeAllSegments()
		cell.segmentedControl?.insertSegment(withTitle: NSLocalizedString("Inactive", comment: ""), at: 0, animated: false)
		cell.segmentedControl?.insertSegment(withTitle: NSLocalizedString("Active", comment: ""), at: 1, animated: false)
		if drones.first?.hasKamikazeAbility == true {
			cell.segmentedControl?.insertSegment(withTitle: NSLocalizedString("True Sacrifice", comment: ""), at: 2, animated: false)
		}
		
		switch (isActive, isKamikaze) {
		case (true, true):
			cell.segmentedControl?.selectedSegmentIndex = 2
		case (true, false):
			cell.segmentedControl?.selectedSegmentIndex = 1
		default:
			cell.segmentedControl?.selectedSegmentIndex = 0
		}
		
		let segmentedControl = cell.segmentedControl!
		
		cell.actionHandler = NCActionHandler(segmentedControl, for: .valueChanged) { [weak self, weak segmentedControl] _ in
			guard let sender = segmentedControl else {return}
			guard let drones = self?.drones else {return}
			let isActive = sender.selectedSegmentIndex > 0
			let isKamikaze = sender.selectedSegmentIndex == 2
			for drone in drones {
				drone.isActive = isActive
				drone.isKamikaze = isKamikaze
			}
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
		}

	}
	
	
	override var hashValue: Int {
		return drones.first?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingDroneStateRow)?.hashValue == hashValue
	}	
}

class NCFittingDroneCountRow: NCCountRow {
	let handler: (Int, NCFittingDroneCountRow) -> Void
	
	var drones: [DGMDrone]
	let ship: DGMShip
	init(drones: [DGMDrone], ship: DGMShip, handler: @escaping (Int, NCFittingDroneCountRow) -> Void) {
		self.drones = drones
		self.ship = ship
		self.handler = handler
		let range: ClosedRange<Int>
		if let drone = drones.first {
			range = 1...(drone.squadron == .none ? 5 : drone.squadronSize)
		}
		else {
			range = 1...5
		}
		
		super.init(value: drones.count, range: Range(range))
	}

	override var hashValue: Int {
		return drones.first?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingDroneCountRow)?.hashValue == hashValue
	}
	
	override func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		super.pickerView(pickerView, didSelectRow: row, inComponent: component)
		handler(value, self)
	}

}


class NCFittingDroneActionsViewController: NCTreeViewController {
	var fleet: NCFittingFleet?
	var drones: [DGMDrone]?
	var type: NCDBInvType? {
		guard let drone = self.drones?.first else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[drone.typeID]
	}
	
	private var observer: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCFittingDroneStateTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCChargeTableViewCell.default,
			])

		
		reload()
		if traitCollection.userInterfaceIdiom == .phone {
			tableView.layoutIfNeeded()
			var size = tableView.contentSize
			if navigationController?.isNavigationBarHidden == false {
				size.height += navigationController!.navigationBar.frame.height
			}
			if navigationController?.isToolbarHidden == false {
				size.height += navigationController!.toolbar.frame.height
			}

			navigationController?.preferredContentSize = size
		}
		
		if observer == nil {
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingFleetDidUpdate, object: fleet, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
		
	}
	
	override func content() -> Future<TreeNode?> {
		return .init(nil)
	}

	@IBAction func onDelete(_ sender: UIButton) {
		guard let drones = self.drones else {return}
		guard let drone = drones.first else {return}
		guard let ship = drone.parent as? DGMShip else {return}
		for drone in drones {
			ship.remove(drone)
		}
		self.drones = nil
		self.dismiss(animated: true, completion: nil)
		NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: fleet)
	}
	
	@IBAction func onChangeState(_ sender: UISegmentedControl) {
		guard let drones = self.drones else {return}
		let isActive = sender.selectedSegmentIndex == 1
		for drone in drones {
			drone.isActive = isActive
		}
		NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: fleet)
	}
	
	
	//MARK: Private
	
	private func reload() {
		guard let fleet = fleet else {return}
		guard let drones = self.drones else {return}
		guard let drone = drones.first else {return}
		guard let type = self.type else {return}
		var sections = [TreeNode]()

		guard let ship = drone.parent as? DGMShip else {return}
		
		let route: Route
		
		if (type.variations?.count ?? 0) > 0 || (type.parentType?.variations?.count ?? 0) > 0 {
			route = Router.Fitting.Variations (type: type) { [weak self] (controller, type) in
				let typeID = Int(type.typeID)
				controller.dismiss(animated: true) {
					guard let drones = self?.drones else {return}
					guard let drone = drones.first else {return}
					guard let ship = drone.parent as? DGMShip else {return}
					let isActive = drone.isActive
					let tag = drone.squadronTag
					let count = drones.count
					var out = [DGMDrone]()
					for drone in drones {
						ship.remove(drone)
					}
					do {
						for _ in 0..<count {
							let drone = try DGMDrone(typeID: typeID)
							try ship.add(drone, squadronTag: tag)
							drone.isActive = isActive
							out.append(drone)
						}
					}
					catch {
						
					}
					self?.drones = out
					NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: fleet)
				}
			}
		}
		else {
			route = Router.Database.TypeInfo(drone)
		}
		
		sections.append(DefaultTreeSection(nodeIdentifier: "Variations",
										   title: NSLocalizedString("Variations", comment: "").uppercased(),
										   children: [NCFittingDroneInfoRow(type: type, drone: drone, count: drones.count, route: route)]))
		
		let handler = {[weak self] (_ count: Int, _ node: NCFittingDroneCountRow) in
			guard let strongSelf = self else {return}
			guard var drones = strongSelf.drones else {return}
			guard let drone = drones.first else {return}
			var n = drones.count - count
			
			let typeID = drone.typeID
			let isActive = drone.isActive
			let tag = drone.squadronTag
			let identifier = drone.identifier
			
			do {
				while n < 0 {
					let drone = try DGMDrone(typeID: typeID)
					try ship.add(drone, squadronTag: tag)
					drone.identifier = identifier
					drone.isActive = isActive
					drones.append(drone)
					n += 1
				}
			}
			catch {
				
			}
			while n > 0 {
				ship.remove(drones.removeLast())
				n -= 1
			}
			strongSelf.drones = drones
			node.drones = drones
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: fleet)
		}
		
		sections.append(DefaultTreeSection(nodeIdentifier: "State", title: NSLocalizedString("State", comment: "").uppercased(), children: [NCFittingDroneStateRow(drones: drones, fleet: fleet)]))
		sections.append(DefaultTreeSection(nodeIdentifier: "Count", title: NSLocalizedString("Count", comment: "").uppercased(), children: [NCFittingDroneCountRow(drones: drones, ship: ship, handler: handler)]))
		
		if treeController?.content == nil {
			treeController?.content = RootNode(sections)
		}
		else {
			treeController?.content?.children = sections
		}
	}

}
