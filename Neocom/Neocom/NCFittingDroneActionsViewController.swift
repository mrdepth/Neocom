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

class NCFittingDroneInfoRow: NCChargeRow {
	let count: Int
	
	init(type: NCDBInvType, drone: NCFittingDrone, count: Int, route: Route? = nil) {
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
	let drones: [NCFittingDrone]
	let isActive: Bool
	init(drones: [NCFittingDrone]) {
		self.drones = drones
		isActive = drones.first?.isActive ?? false
		super.init(prototype: Prototype.NCFittingDroneStateTableViewCell.default)
		
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingDroneStateTableViewCell else {return}
		cell.object = self
		cell.segmentedControl?.selectedSegmentIndex = isActive ? 1 : 0
		
		let segmentedControl = cell.segmentedControl!
		
		cell.actionHandler = NCActionHandler(segmentedControl, for: .valueChanged) { [weak self, weak segmentedControl] _ in
			guard let sender = segmentedControl else {return}
			guard let drones = self?.drones else {return}
			let isActive = sender.selectedSegmentIndex == 1
			drones.first?.engine?.perform {
				for drone in drones {
					drone.isActive = isActive
				}
			}
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
	
	var drones: [NCFittingDrone]
	let ship: NCFittingShip
	init(drones: [NCFittingDrone], ship: NCFittingShip, handler: @escaping (Int, NCFittingDroneCountRow) -> Void) {
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
	var drones: [NCFittingDrone]?
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
		
		if let drone = drones?.first, observer == nil {
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingEngineDidUpdate, object: drone.engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
		
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		completionHandler()
	}

	@IBAction func onDelete(_ sender: UIButton) {
		guard let drones = self.drones else {return}
		guard let drone = drones.first else {return}
		drone.engine?.perform {
			guard let ship = drone.owner as? NCFittingShip else {return}
			for drone in drones {
				ship.removeDrone(drone)
			}
		}
		self.dismiss(animated: true, completion: nil)
	}
	
	@IBAction func onChangeState(_ sender: UISegmentedControl) {
		guard let drones = self.drones else {return}
		let isActive = sender.selectedSegmentIndex == 1
		drones.first?.engine?.perform {
			for drone in drones {
				drone.isActive = isActive
			}
		}
	}
	
	
	//MARK: Private
	
	private func reload() {
		guard let drones = self.drones else {return}
		guard let drone = drones.first else {return}
		guard let type = self.type else {return}
		var sections = [TreeNode]()

		drone.engine?.performBlockAndWait {
			guard let ship = drone.owner as? NCFittingShip else {return}
			
			let route: Route
			
			if (type.variations?.count ?? 0) > 0 || (type.parentType?.variations?.count ?? 0) > 0 {
				route = Router.Fitting.Variations (type: type) { [weak self] (controller, type) in
					let typeID = Int(type.typeID)
					controller.dismiss(animated: true) {
						guard let drones = self?.drones else {return}
						guard let drone = drones.first else {return}
						drone.engine?.perform {
							guard let ship = drone.owner as? NCFittingShip else {return}
							let isActive = drone.isActive
							let tag = drone.squadronTag
							let count = drones.count
							var out = [NCFittingDrone]()
							for drone in drones {
								ship.removeDrone(drone)
							}
							for _ in 0..<count {
								guard let drone = ship.addDrone(typeID: typeID, squadronTag: tag) else {break}
								drone.isActive = isActive
								out.append(drone)
							}
							self?.drones = out
						}
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
				guard let engine = ship.engine else {return}
				engine.performBlockAndWait {
					var n = drones.count - count

					let typeID = drone.typeID
					let isActive = drone.isActive
					let tag = drone.squadronTag
					let identifier = drone.identifier

					while n < 0 {
						if let drone = ship.addDrone(typeID: typeID, squadronTag: tag) {
							drone.isActive = isActive
							engine.assign(identifier: identifier, for: drone)
							drones.append(drone)
						}
						else {
							break
						}
						n += 1
					}
					while n > 0 {
						ship.removeDrone(drones.removeLast())
						n -= 1
					}
					strongSelf.drones = drones
					node.drones = drones
				}
			}
			
			sections.append(DefaultTreeSection(nodeIdentifier: "State", title: NSLocalizedString("State", comment: "").uppercased(), children: [NCFittingDroneStateRow(drones: drones)]))
			sections.append(DefaultTreeSection(nodeIdentifier: "Count", title: NSLocalizedString("Count", comment: "").uppercased(), children: [NCFittingDroneCountRow(drones: drones, ship: ship, handler: handler)]))
			
		}
		
		if treeController?.content == nil {
			treeController?.content = RootNode(sections)
		}
		else {
			treeController?.content?.children = sections
		}
	}

}
