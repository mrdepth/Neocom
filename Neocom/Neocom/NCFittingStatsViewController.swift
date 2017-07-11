//
//  NCFittingStatsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData

class NCFittingFuelRow: TreeRow {
	let structure: NCFittingStructure
	
	init(structure: NCFittingStructure) {
		self.structure = structure
		super.init(prototype: Prototype.NCDefaultTableViewCell.default)
	}
	
	lazy var type: NCDBInvType? = {
		guard let engine = self.structure.engine else {return nil}
		let typeID = engine.sync {self.structure.fuelBlockTypeID}
		return NCDatabase.sharedDatabase?.invTypes[typeID]
	}()
	
	var price: Double?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		
		guard let engine = self.structure.engine else {return}

		if let price = price {
			let (cycleFuelNeed, cycleTime) = engine.sync{(self.structure.cycleFuelNeed, self.structure.cycleTime)}
			cell.subtitleLabel?.text = String.init(format: NSLocalizedString("%@/h (%@/day)", comment: ""), NCUnitFormatter.localizedString(from: cycleFuelNeed / cycleTime * 3600, unit: .none, style: .full), NCUnitFormatter.localizedString(from: cycleFuelNeed / cycleTime * 3600 * 24 * price, unit: .isk, style: .full))
		}
		else {
			let typeID = engine.sync {self.structure.fuelBlockTypeID}
			
			NCDataManager(account: NCAccount.current).prices(typeIDs: Set([typeID])) { result in
				self.price = result[typeID] ?? 0
				self.treeController?.reloadCells(for: [self], with: .none)
			}
		}
	}
	
	override var hashValue: Int {
		return "FuelRow".hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingFuelRow)?.hashValue == hashValue
	}
	
}

class NCFittingPriceSection: TreeSection {
	let ship: NCFittingShip
	let typeIDs: [Int: Int]
	
	var prices: [Int: Double]? {
		didSet {
			(self.children as? [NCFittingPriceRow])?.forEach {$0.prices = prices}
		}
	}
	
	init(ship: NCFittingShip) {
		self.ship = ship
		var children: [TreeNode] = [NCFittingPriceTypeRow(typeID: ship.typeID, quantity: 1)]
		
		var typeIDs = [Int: Int]()
		typeIDs[ship.typeID] = 1
		
		if !ship.modules.isEmpty {
			let row = NCFittingPriceModulesRow(ship: ship)
			row.typeIDs.forEach {
				typeIDs[$0.key] = (typeIDs[$0.key] ?? 0) + $0.value
			}
			children.append(row)
		}
		if !ship.drones.isEmpty {
			let row = NCFittingPriceDronesRow(ship: ship)
			row.typeIDs.forEach {
				typeIDs[$0.key] = (typeIDs[$0.key] ?? 0) + $0.value
			}
			children.append(row)
		}
		if (ship.owner as? NCFittingCharacter)?.implants.all.isEmpty == false {
			let row = NCFittingPriceImplantsRow(ship: ship)
			row.typeIDs.forEach {
				typeIDs[$0] = (typeIDs[$0] ?? 0) + 1
			}
			children.append(row)
		}
		
		self.typeIDs = typeIDs
		
		super.init(prototype: Prototype.NCHeaderTableViewCell.default)

		self.children = children
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		
		var cost: Double = 0
		if let prices = prices {
			typeIDs.forEach {
				cost += (prices[$0.key] ?? 0) * Double($0.value)
			}
		}
		cell.titleLabel?.text = NSLocalizedString("Cost:", comment: "").uppercased() + (cost > 0 ? " \(NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .full))" : "")
	}
	
	override var hashValue: Int {
		return "Cost".hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingPriceSection)?.hashValue == hashValue
	}

}

class NCFittingPriceRow: TreeRow {
	var prices: [Int: Double]? {
		didSet {
			treeController?.reloadCells(for: [self], with: .none)
			(self.children as? [NCFittingPriceRow])?.forEach {$0.prices = prices}
		}
	}
}

class NCFittingPriceTypeRow: NCFittingPriceRow {
	let typeID: Int
	let quantity: Int
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.typeID]
	}()
	
	init(typeID: Int, quantity: Int) {
		self.typeID = typeID
		self.quantity = quantity
		super.init(prototype: Prototype.NCDefaultTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		let typeName = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		if quantity > 1 {
			cell.titleLabel?.attributedText = typeName + " x\(NCUnitFormatter.localizedString(from: quantity, unit: .none, style: .full))" * [NSForegroundColorAttributeName: UIColor.caption]
		}
		else {
			cell.titleLabel?.text = typeName
		}
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		
		if let price = prices?[typeID] {
			cell.subtitleLabel?.text = "\(NCUnitFormatter.localizedString(from: Double(quantity) * price, unit: .isk, style: .full))"
		}
		else {
			cell.subtitleLabel?.text = nil
		}
		
		
	}
	
	override var hashValue: Int {
		return typeID.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingPriceTypeRow)?.hashValue == hashValue
	}

}


class NCFittingPriceModulesRow: NCFittingPriceRow {
	let ship: NCFittingShip
	let typeIDs: [Int: Int]
	
	init(ship: NCFittingShip) {
		self.ship = ship
		var typeIDs = [Int: Int]()
		ship.modules.forEach {
			typeIDs[$0.typeID] = (typeIDs[$0.typeID] ?? 0) + 1
		}
		self.typeIDs = typeIDs
		
		super.init(prototype: Prototype.NCDefaultTableViewCell.default)
		isExpanded = false
		isExpandable = true
		children = typeIDs.sorted{$0.key < $1.key}.map {NCFittingPriceTypeRow(typeID: $0.key, quantity: $0.value)}
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = NSLocalizedString("Modules", comment: "")
		cell.iconView?.image = #imageLiteral(resourceName: "priceFitting")
		
		var cost: Double = 0
		if let prices = prices {
			typeIDs.forEach {
				cost += (prices[$0.key] ?? 0) * Double($0.value)
			}
		}
		cell.subtitleLabel?.text = cost > 0 ? NSLocalizedString("Cost:", comment: "") + " \(NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .full))" : nil
	}
	
	override var hashValue: Int {
		return "Modules".hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingPriceModulesRow)?.hashValue == hashValue
	}
	
}

class NCFittingPriceDronesRow: NCFittingPriceRow {
	let ship: NCFittingShip
	let typeIDs: [Int: Int]

	init(ship: NCFittingShip) {
		self.ship = ship
		var typeIDs = [Int: Int]()
		ship.drones.forEach {
			typeIDs[$0.typeID] = (typeIDs[$0.typeID] ?? 0) + 1
		}
		self.typeIDs = typeIDs

		super.init(prototype: Prototype.NCDefaultTableViewCell.default)
		isExpanded = false
		isExpandable = true
		children = typeIDs.sorted{$0.key < $1.key}.map {NCFittingPriceTypeRow(typeID: $0.key, quantity: $0.value)}
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = NSLocalizedString("Drones", comment: "")
		cell.iconView?.image = #imageLiteral(resourceName: "drone")
		
		var cost: Double = 0
		if let prices = prices {
			typeIDs.forEach {
				cost += (prices[$0.key] ?? 0) * Double($0.value)
			}
		}
		cell.subtitleLabel?.text = cost > 0 ? NSLocalizedString("Cost:", comment: "") + " \(NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .full))" : nil
	}

	
	override var hashValue: Int {
		return "Drones".hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingPriceDronesRow)?.hashValue == hashValue
	}

}

class NCFittingPriceImplantsRow: NCFittingPriceRow {
	let ship: NCFittingShip
	let typeIDs: [Int]
	
	init(ship: NCFittingShip) {
		self.ship = ship
		typeIDs = (ship.owner as? NCFittingCharacter)?.implants.all.map{$0.typeID} ?? []
		super.init(prototype: Prototype.NCDefaultTableViewCell.default)
		
		children = typeIDs.map {NCFittingPriceTypeRow(typeID: $0, quantity: 1)}
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = NSLocalizedString("Implants", comment: "")
		cell.iconView?.image = #imageLiteral(resourceName: "implant")
		
		var cost: Double = 0
		if let prices = prices {
			typeIDs.forEach {
				cost += prices[$0] ?? 0
			}
		}
		cell.subtitleLabel?.text = cost > 0 ? NSLocalizedString("Cost:", comment: "") + " \(NCUnitFormatter.localizedString(from: cost, unit: .isk, style: .full))" : nil
	}
	
	override var hashValue: Int {
		return "Implants".hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingPriceImplantsRow)?.hashValue == hashValue
	}

}


class NCFittingStatsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet weak var treeController: TreeController!

	var engine: NCFittingEngine? {
		return (parent as? NCFittingEditorViewController)?.engine
	}
	
	var fleet: NCFittingFleet? {
		return (parent as? NCFittingEditorViewController)?.fleet
	}
	
	private var observer: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default])

		
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
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
	}
	
	@IBAction func onReloadFactor(_ sender: UISwitch) {
		guard let engine = engine else {return}
		let factor = sender.isOn
		engine.perform {
			engine.factorReload = factor
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		treeController.deselectCell(for: node, animated: true)
		guard let route = (node as? TreeNodeRoutable)?.route else {return}
		route.perform(source: self, view: treeController.cell(for: node))
	}
	
	//MARK: - Private
	
	private func reload() {
		engine?.perform {
			guard let pilot = self.fleet?.active else {return}
			guard let ship = pilot.ship ?? pilot.structure else {return}
			var sections = [TreeNode]()
			
			sections.append(DefaultTreeSection(nodeIdentifier: "Resources", title: NSLocalizedString("Resources", comment: "").uppercased(), children: [NCFittingResourcesRow(ship: ship)]))
			sections.append(DefaultTreeSection(nodeIdentifier: "Resistances", title: NSLocalizedString("Resistances", comment: "").uppercased(), children: [NCResistancesRow(ship: ship)]))
			sections.append(DefaultTreeSection(nodeIdentifier: "Capacitor", title: NSLocalizedString("Capacitor", comment: "").uppercased(), children: [NCFittingCapacitorRow(ship: ship)]))
			sections.append(DefaultTreeSection(nodeIdentifier: "Tank", title: NSLocalizedString("Recharge Rates (HP/s, EHP/s)", comment: "").uppercased(), children: [NCTankRow(ship: ship)]))
			sections.append(DefaultTreeSection(nodeIdentifier: "Firepower", title: NSLocalizedString("Firepower", comment: "").uppercased(), children: [NCFirepowerRow(ship: ship)]))
			if ship.minerYield > 0 || ship.droneYield > 0 {
				sections.append(DefaultTreeSection(nodeIdentifier: "Mining", title: NSLocalizedString("Mining", comment: "").uppercased(), children: [NCMiningYieldRow(ship: ship)]))
			}
			if let structure = pilot.structure {
				sections.append(DefaultTreeSection(nodeIdentifier: "Misc", title: NSLocalizedString("Misc", comment: "").uppercased(), children: [NCFittingMiscRow(structure: structure)]))
				sections.append(DefaultTreeSection(nodeIdentifier: "Fuel", title: NSLocalizedString("Fuel", comment: "").uppercased(), children: [NCFittingFuelRow(structure: structure)]))
			}
			else {
				sections.append(DefaultTreeSection(nodeIdentifier: "Misc", title: NSLocalizedString("Misc", comment: "").uppercased(), children: [NCFittingMiscRow(ship: ship)]))
			}
			let pricesSection = NCFittingPriceSection(ship: ship)
			sections.append(pricesSection)
			
			var typeIDs = Set(ship.modules.map {[$0.typeID, $0.charge?.typeID]}.joined().flatMap{$0})
			typeIDs.formUnion(Set(ship.drones.map{$0.typeID}))
			typeIDs.insert(ship.typeID)

			DispatchQueue.main.async {
				self.treeController.content?.children = sections
				NCDataManager(account: NCAccount.current).prices(typeIDs: typeIDs) { result in
					pricesSection.prices = result
				}
			}
		}
	}
}
