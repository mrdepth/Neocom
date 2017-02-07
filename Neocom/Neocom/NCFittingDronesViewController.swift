//
//  NCFittingDronesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 06.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingDroneRow: TreeRow {
	lazy var type: NCDBInvType? = {
		guard let drone = self.drones.first else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[drone.typeID]
	}()
	
	let drones: [NCFittingDrone]
	let isActive: Bool
	let hasTarget: Bool

	init(drones: [NCFittingDrone]) {
		let drone = drones.first
		self.drones = drones
		isActive = drone?.isActive == true
		hasTarget = drone?.target != nil
		super.init(cellIdentifier: "ModuleCell")
	}
	
	override func changed(from: TreeNode) -> Bool {
		guard let from = from as? NCFittingDroneRow else {return false}
		subtitle = from.subtitle
		return true
	}
	
	var needsUpdate: Bool = true
	var subtitle: NSAttributedString?
	
	override func configure(cell: UITableViewCell) {
		let drone = drones.first
		guard let cell = cell as? NCFittingModuleTableViewCell else {return}
		cell.object = drones
		
		if drones.count > 1 {
			cell.titleLabel?.attributedText = (type?.typeName ?? "") + " " + "x\(drones.count)" * [NSForegroundColorAttributeName: UIColor.caption]
		}
		else {
			cell.titleLabel?.text = type?.typeName
		}
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		
		cell.stateView?.image = isActive ? #imageLiteral(resourceName: "active") : #imageLiteral(resourceName: "offline")
		cell.subtitleLabel?.attributedText = subtitle
		cell.targetIconView.image = hasTarget ? #imageLiteral(resourceName: "targets") : nil
		
		cell.subtitleLabel?.superview?.isHidden = subtitle == nil || subtitle?.length == 0
		
		if needsUpdate {
			let font = cell.subtitleLabel!.font!
			
			guard let drone = drone else {return}
			
			drone.engine?.perform {
				let string = NSMutableAttributedString()

				let optimal = drone.maxRange
				let falloff = drone.falloff
				let velocity = drone.velocity
				
				if optimal > 0 {
					let s: NSAttributedString
					let attr = [NSForegroundColorAttributeName: UIColor.caption]
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
					let s = NSAttributedString(image: #imageLiteral(resourceName: "velocity"), font: font) + " \(NSLocalizedString("velocity", comment: "")): " + NCUnitFormatter.localizedString(from: velocity, unit: .meterPerSecond, style: .full) * [NSForegroundColorAttributeName: UIColor.caption]
					string.appendLine(s)
				}
				
				DispatchQueue.main.async {
					self.needsUpdate = false
					self.subtitle = string
					guard let tableView = cell.tableView else {return}
					guard let indexPath = tableView.indexPath(for: cell) else {return}
					tableView.reloadRows(at: [indexPath], with: .fade)
				}
			}
		}
		else {
			cell.subtitleLabel?.attributedText = subtitle
		}
	}
	
	override var hashValue: Int {
		return drones.first?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingDroneRow)?.hashValue == hashValue
	}
}

class NCFittingDroneSection: TreeSection {
	let squadron: NCFittingFighterSquadron
	let used: Int
	let limit: Int
	init(squadron: NCFittingFighterSquadron, ship: NCFittingShip, children: [NCFittingDroneRow]) {
		self.squadron = squadron
		used = ship.droneSquadronUsed(squadron)
		limit = ship.droneSquadronLimit(squadron)
		super.init(cellIdentifier: "NCHeaderTableViewCell")
		self.children = children
	}
	
	override var isExpandable: Bool {
		return false
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.iconView?.image = #imageLiteral(resourceName: "drone")
		if squadron == .none {
			cell.titleLabel?.text = squadron.title
		}
		else {
			cell.titleLabel?.attributedText = (squadron.title ?? "") + "used/limit" * [NSForegroundColorAttributeName: UIColor.caption]
		}
	}
	
	override var hashValue: Int {
		return squadron.rawValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingModuleSection)?.hashValue == hashValue
	}
	
	override func changed(from: TreeNode) -> Bool {
		return (from as? NCFittingDroneSection)?.used != used || (from as? NCFittingDroneSection)?.limit != limit
	}
	
}

class NCActionRow: DefaultTreeRow {
	
	override var hashValue: Int {
		return segue?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCActionRow)?.hashValue == hashValue
	}
	
	override func changed(from: TreeNode) -> Bool {
		return false
	}
	
}


class NCFittingDronesViewController: UIViewController, TreeControllerDelegate {
	@IBOutlet weak var treeController: TreeController!
	@IBOutlet weak var tableView: UITableView!

	@IBOutlet weak var droneBayLabel: NCResourceLabel!
	@IBOutlet weak var droneBandwidthLabel: NCResourceLabel!
	@IBOutlet weak var dronesCountLabel: UILabel!
	
	var engine: NCFittingEngine? {
		return (parent as? NCShipFittingViewController)?.engine
	}
	
	var fleet: NCFleet? {
		return (parent as? NCShipFittingViewController)?.fleet
	}
	
	var typePickerViewController: NCTypePickerViewController? {
		return (parent as? NCShipFittingViewController)?.typePickerViewController
	}
	
	private var observer: NSObjectProtocol?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		droneBandwidthLabel.unit = .megaBitsPerSecond
		droneBayLabel.unit = .cubicMeter
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
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if node is NCFittingDroneRow {
			performSegue(withIdentifier: "NCFittingDroneActionsViewController", sender: treeController.cell(for: node))
		}
		else if let item = node as? DefaultTreeRow, item.segue == "NCTypePickerViewController" {
			guard let pilot = fleet?.active else {return}
			guard let typePickerViewController = typePickerViewController else {return}
			let category = NCDBDgmppItemCategory.category(categoryID: .drone, subcategory:  NCDBCategoryID.drone.rawValue)
			
			typePickerViewController.category = category
			typePickerViewController.completionHandler = { [weak typePickerViewController] type in
				let typeID = Int(type.typeID)
				self.engine?.perform {
					guard let ship = pilot.ship else {return}
					//let n = ship.droneSquadronLimit(.none)
					let tag = (ship.drones.flatMap({$0.squadron == .none ? $0.squadronTag : nil}).max() ?? -1) + 1
					for _ in 0..<5 {
						ship.addDrone(typeID: typeID, squadronTag: tag)
					}
				}
				typePickerViewController?.dismiss(animated: true)
			}
			present(typePickerViewController, animated: true)

		}
	}

	//MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCFittingDroneActionsViewController"?:
			guard let controller = (segue.destination as? UINavigationController)?.topViewController as? NCFittingDroneActionsViewController else {return}
			guard let cell = sender as? NCFittingModuleTableViewCell else {return}
			controller.drones = cell.object as? [NCFittingDrone]
		default:
			break
		}
	}
	
	//MARK: - Private
	
	private func update() {
		engine?.perform {
			guard let ship = self.fleet?.active?.ship else {return}
			let droneBayUsed = ship.droneBayUsed
			let totalDroneBay = ship.totalDroneBay
			let droneBandwidthUsed = ship.droneBandwidthUsed
			let totalDroneBandwidth = ship.totalDroneBandwidth
			let isCarrier = ship.totalFighterLaunchTubes > 0
			let droneSquadronLimit = isCarrier ? ship.totalFighterLaunchTubes : ship.droneSquadronLimit(.none)
			let droneSquadronUsed = isCarrier ? ship.fighterLaunchTubesUsed : ship.droneSquadronUsed(.none)
			let dronesColor = droneSquadronUsed <= droneSquadronLimit ? UIColor.white : UIColor.red

			DispatchQueue.main.async {
				self.droneBayLabel.value = droneBayUsed
				self.droneBayLabel.maximumValue = totalDroneBay
				self.droneBandwidthLabel.value = droneBandwidthUsed
				self.droneBandwidthLabel.maximumValue = totalDroneBandwidth
				self.dronesCountLabel.text = "\(droneSquadronUsed)/\(droneSquadronLimit)"
				self.dronesCountLabel.textColor = dronesColor
			}
		}
	}
	
	private func reload() {
		engine?.perform {
			guard let ship = self.fleet?.active?.ship else {return}
			
			var squadrons = [Int: [Int: [Bool: [NCFittingDrone]]]]()
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
			
			rows.append(NCActionRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "drone"), title: NSLocalizedString("Add Drone", comment: ""), segue: "NCTypePickerViewController"))
			/*typealias TypeID = Int
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
			
			sections.append(DefaultTreeRow(cellIdentifier: "Cell", image: #imageLiteral(resourceName: "drone"), title: NSLocalizedString("Add Drone", comment: ""), segue: "NCTypePickerViewController"))*/
			
			DispatchQueue.main.async {
				if self.treeController.rootNode == nil {
					self.treeController.rootNode = TreeNode()
				}
				self.treeController.rootNode?.children = rows
			}
		}
		update()
	}

}
