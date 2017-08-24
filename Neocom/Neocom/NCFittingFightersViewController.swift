//
//  NCFittingFightersViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 10.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData

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
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if self.treeController.content == nil {
			self.treeController.content = TreeNode()
			reload()
		}
		
		if observer == nil {
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		treeController.deselectCell(for: node, animated: true)
		if let node = node as? NCFittingDroneRow {
			Router.Fitting.DroneActions(node.drones).perform(source: self, sender: treeController.cell(for: node))
		}
		else if node is NCActionRow {
			guard let pilot = fleet?.active else {return}
			guard let typePickerViewController = typePickerViewController else {return}
			guard let engine = self.engine else {return}
			
			let category = NCDBDgmppItemCategory.category(categoryID: .drone, subcategory:  NCDBCategoryID.fighter.rawValue)
			
			typePickerViewController.category = category
			typePickerViewController.completionHandler = { [weak typePickerViewController, weak self] (_, type) in
				let typeID = Int(type.typeID)
				engine.perform {
					guard let ship = pilot.ship ?? pilot.structure else {return}
//					let tag = (ship.drones.flatMap({$0.squadron == .none ? $0.squadronTag : nil}).max() ?? -1) + 1
					let tag = -1
					let identifier = UUID().uuidString
					
					guard let drone = ship.addDrone(typeID: typeID, squadronTag: tag) else {return}
					engine.assign(identifier: identifier, for: drone)
					for _ in 1..<drone.squadronSize {
						guard let drone = ship.addDrone(typeID: typeID, squadronTag: tag) else {continue}
						engine.assign(identifier: identifier, for: drone)
					}
				}
				typePickerViewController?.dismiss(animated: true)
				if self?.traitCollection.horizontalSizeClass == .compact || self?.traitCollection.userInterfaceIdiom == .phone {
					typePickerViewController?.dismiss(animated: true)
				}

			}
			Route(kind: .popover, viewController: typePickerViewController).perform(source: self, sender: treeController.cell(for: node))
			
		}
	}
	
	//MARK: - Private
	
	private func update() {
		engine?.perform {
			guard let pilot = self.fleet?.active else {return}
			guard let ship = pilot.ship ?? pilot.structure else {return}
			let droneBay = (ship.fighterHangarUsed, ship.totalFighterHangar)
			let droneSquadron = (ship.fighterLaunchTubesUsed, ship.totalFighterLaunchTubes)
			
			DispatchQueue.main.async {
				self.droneBayLabel.value = droneBay.0
				self.droneBayLabel.maximumValue = droneBay.1
				self.dronesCountLabel.text = "\(droneSquadron.0)/\(droneSquadron.1)"
				self.dronesCountLabel.textColor = droneSquadron.0 > droneSquadron.1 ? .red : .white
			}
		}
	}
	
	private func reload() {
		engine?.perform {
			guard let pilot = self.fleet?.active else {return}
			guard let ship = pilot.ship ?? pilot.structure else {return}
			
			/*var squadrons = [Int: [Int: [Bool: [NCFittingDrone]]]]()
			for drone in ship.drones.filter({$0.squadron == .none} ) {
				var a = squadrons[drone.squadronTag] ?? [:]
				var b = a[drone.typeID] ?? [:]
				var c = b[drone.isActive] ?? []
				c.append(drone)
				b[drone.isActive] = c
				a[drone.typeID] = b
				squadrons[drone.squadronTag] = a
			}
			
			var rows = [TreeNode]()
			for (_, array) in squadrons.sorted(by: { (a, b) -> Bool in return a.key < b.key } ) {
				for (_, array) in array.sorted(by: { (a, b) -> Bool in return (a.value.first?.value.first?.typeName ?? "") < (b.value.first?.value.first?.typeName ?? "") }) {
					for (_, array) in array.sorted(by: { (a, b) -> Bool in return a.key }) {
						rows.append(NCFittingDroneRow(drones: array))
					}
				}
			}
			
			rows.append(NCActionRow(title: NSLocalizedString("Add Drone", comment: "").uppercased()))*/
			
			
			
			
			
			typealias TypeID = Int
			typealias Squadron = [Int: [TypeID: [Bool: [NCFittingDrone]]]]
			var squadrons = [NCFittingFighterSquadron: Squadron]()
			for squadron in [NCFittingFighterSquadron.none, NCFittingFighterSquadron.heavy, NCFittingFighterSquadron.light, NCFittingFighterSquadron.support] {
				if ship.droneSquadronLimit(squadron) > 0 {
					squadrons[squadron] = [:]
				}
			}
			
			for drone in ship.drones {
				var squadron = squadrons[drone.squadron] ?? [:]
				var types = squadron[drone.squadronTag] ?? [:]
				var drones = types[drone.typeID] ?? [:]
				var array = drones[drone.isActive] ?? []
				array.append(drone)
				drones[drone.isActive] = array
				types[drone.typeID] = drones
				squadron[drone.squadronTag] = types
				squadrons[drone.squadron] = squadron
			}
			
			var sections = [TreeNode]()
			for (type, squadron) in squadrons.sorted(by: { (a, b) -> Bool in return a.key.rawValue < b.key.rawValue}) {
				var rows = [NCFittingDroneRow]()
				for (_, types) in squadron.sorted(by: { (a, b) -> Bool in return a.key < b.key }) {
					for (_, drones) in types.sorted(by: { (a, b) -> Bool in return a.value.first?.value.first?.typeName ?? "" < b.value.first?.value.first?.typeName ?? "" }) {
						for (_, array) in drones.sorted(by: { (a, b) -> Bool in return a.key }) {
							rows.append(NCFittingDroneRow(drones: array))
						}
					}
				}
				if type == .none {
					sections.append(contentsOf: rows as [TreeNode])
				}
				else {
					let section = NCFittingDroneSection(squadron: type, ship: ship, children: rows)
					sections.append(section)
				}
			}
			
			sections.append(NCActionRow(title: NSLocalizedString("Add Drone", comment: "").uppercased()))
			
			
			
			
			
			DispatchQueue.main.async {
				self.treeController.content?.children = sections
			}
		}
		update()
	}
	
}
