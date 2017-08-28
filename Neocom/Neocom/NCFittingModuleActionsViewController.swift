//
//  NCFittingModuleActionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 31.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData

class NCFittingModuleStateRow: TreeRow {
	let modules: [NCFittingModule]
	let states: [NCFittingModuleState]
	
	init(modules: [NCFittingModule]) {
		self.modules = modules
		let module = modules.first!
		let states: [NCFittingModuleState] = [.offline, .online, .active, .overloaded]
		self.states = states.filter {module.canHaveState($0)}
		
		super.init(prototype: Prototype.NCFittingModuleStateTableViewCell.default)
		
	}
	
	var actionHandler: NCActionHandler?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingModuleStateTableViewCell else {return}
		cell.segmentedControl?.removeAllSegments()
		cell.object = self
		var i = 0
		for state in states {
			cell.segmentedControl?.insertSegment(withTitle: state.title, at: i, animated: false)
			i += 1
		}
		guard let module = modules.first else {return}

		let segmentedControl = cell.segmentedControl!
		self.actionHandler = NCActionHandler(segmentedControl, for: .valueChanged) { [weak self, weak segmentedControl] _ in
			guard let sender = segmentedControl else {return}
			guard let state = self?.states[sender.selectedSegmentIndex] else {return}
			module.engine?.perform {
				for module in self?.modules ?? [] {
					module.state = state
				}
			}

		}
		module.engine?.perform {
			let state = module.state
			DispatchQueue.main.async {
				if let i = self.states.index(of: state) {
					cell.segmentedControl?.selectedSegmentIndex = i
				}
			}
		}
	}
	

	override var hashValue: Int {
		return modules.first?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingModuleStateRow)?.hashValue == hashValue
	}
	
}

class NCFittingModuleInfoRow: TreeRow {
	let module: NCFittingModule
	let cpu: Double
	let powerGrid: Double
	let capacitor: Double
	let count: Int
	
	let type: NCDBInvType
	
	init(module: NCFittingModule, type: NCDBInvType, count: Int, route: Route? = nil) {
		self.module = module
		self.count = count
		let cpu = module.cpuUse
		let powerGrid = module.powerGridUse
		let capacitor = module.capUse
		self.cpu = cpu
		self.powerGrid = powerGrid
		self.capacitor = capacitor
		self.type = type
		
		if cpu != 0 || powerGrid != 0 || capacitor != 0 {
			super.init(prototype: Prototype.NCFittingModuleInfoTableViewCell.default, route: route, accessoryButtonRoute: Router.Database.TypeInfo(module))
		}
		else {
			super.init(prototype: Prototype.NCDefaultTableViewCell.compact, route: route, accessoryButtonRoute: Router.Database.TypeInfo(module))
		}
	}
	
	override func configure(cell: UITableViewCell) {
		let title: NSAttributedString
		if count > 1 {
			title = (type.typeName ?? "") + " " + "x\(count)" * [NSForegroundColorAttributeName: UIColor.caption]
		}
		else {
			title = NSAttributedString(string: type.typeName ?? "")
		}

		
		if let cell = cell as? NCFittingModuleInfoTableViewCell {
			cell.titleLabel?.attributedText = title
			cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.object = type
			cell.powerGridLabel?.text = NCUnitFormatter.localizedString(from: powerGrid, unit: .megaWatts, style: .short)
			cell.cpuLabel?.text = NCUnitFormatter.localizedString(from: cpu, unit: .teraflops, style: .short)
			cell.capUseLabel?.text = (capacitor < 0 ? "+" : "") + NCUnitFormatter.localizedString(from: -capacitor, unit: .gigaJoule, style: .short)
		}
		else if let cell = cell as? NCDefaultTableViewCell {
			cell.titleLabel?.attributedText = title
			cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.object = type
			cell.accessoryType = .detailButton
		}
	}

	override var hashValue: Int {
		return module.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingModuleInfoRow)?.hashValue == hashValue
	}
}

class NCFittingChargeRow: NCChargeRow {
	let charges: Int
	init(type: NCDBInvType, charges: Int, route: Route? = nil) {
		self.charges = charges
		super.init(prototype: Prototype.NCChargeTableViewCell.compact, type: type, route: route, accessoryButtonRoute: Router.Database.TypeInfo(type))
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		if charges > 0 {
			let title = (type.typeName ?? "") + " x\(charges)" * [NSForegroundColorAttributeName: UIColor.caption]
			if let cell = cell as? NCChargeTableViewCell {
				cell.titleLabel?.attributedText = title
			}
			else if let cell = cell as? NCDefaultTableViewCell{
				cell.titleLabel?.attributedText = title
				cell.accessoryType = .detailButton
			}

		}
	}
}

class NCFittingModuleActionsViewController: UITableViewController, TreeControllerDelegate {
	var modules: [NCFittingModule]?
	var type: NCDBInvType? {
		guard let module = self.modules?.first else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[module.typeID]
	}

	lazy var hullType: NCDBDgmppHullType? = {
		guard let module = self.modules?.first else {return nil}
		var targetTypeID: Int?
		module.engine?.performBlockAndWait {
			targetTypeID = module.target?.typeID
		}
		if let targetTypeID = targetTypeID, let hullType = NCDatabase.sharedDatabase?.invTypes[targetTypeID]?.hullType {
			return hullType
		}
		guard let ship = self.modules?.first?.owner as? NCFittingShip else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[ship.typeID]?.hullType
	}()

	var chargeCategory: NCDBDgmppItemCategory? {
		return self.type?.dgmppItem?.charge
	}
	
	var chargeSection: DefaultTreeSection?

	
	@IBOutlet var treeController: TreeController!
	
	private var observer: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		

		
		tableView.register([Prototype.NCFittingModuleStateTableViewCell.default,
		                    Prototype.NCDamageTypeTableViewCell.compact,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCChargeTableViewCell.compact,
		                    Prototype.NCActionTableViewCell.default,
		                    Prototype.NCFleetMemberTableViewCell.default
			])

		

		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		reload()
		if traitCollection.userInterfaceIdiom == .phone {
			tableView.layoutIfNeeded()
			var size = tableView.contentSize
			size.height += tableView.contentInset.top
			size.height += tableView.contentInset.bottom
			navigationController?.preferredContentSize = size
		}

		if let module = modules?.first, observer == nil {
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingEngineDidUpdate, object: module.engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}

	}

	@IBAction func onDelete(_ sender: UIButton) {
		guard let modules = self.modules else {return}
		guard let module = modules.first else {return}
		module.engine?.perform {
			guard let ship = module.owner as? NCFittingShip else {return}
			for module in modules {
				ship.removeModule(module)
			}
		}
		self.dismiss(animated: true, completion: nil)
	}

	@IBAction func onChangeHullType(_ sender: UIStepper) {
		guard let cell = sender.ancestor(of: NCFittingModuleDamageChartTableViewCell.self) else {return}
		guard let node = cell.object as? NCFittingModuleDamageChartRow else {return}
		guard let hullType = node.hullTypes?[Int(sender.value)] else {return}
		self.hullType = hullType
		node.hullType = hullType
		node.configure(cell: cell)
		//treeController.reloadCells(for: [node])
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? TreeRow else {return}
		guard let route = node.route else {return}
		route.perform(source: self, sender: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let node = node as? TreeRow else {return}
		guard let route = node.accessoryButtonRoute else {return}
		route.perform(source: self, sender: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		if node is NCFittingChargeRow {
			return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Unload", comment: "Unload ammo"), handler: { _ in
				guard let modules = self.modules else {return}
				
				modules.first?.engine?.perform {
					for module in modules {
						module.charge = nil
					}
				}
				
				let ammoRoute = Router.Fitting.Ammo(category: self.chargeCategory!, modules: modules) { [weak self] (controller, type) in
					self?.setAmmo(controller: controller, type: type)
				}

				
				let row = NCActionRow(title: NSLocalizedString("Select Ammo", comment: ""),  route: ammoRoute)
				self.chargeSection?.children = [row]

			})]
		}
		return nil
	}
	
	//MARK: Private
	
	private func setAmmo(controller: NCFittingAmmoViewController, type: NCDBInvType?) {
		let typeID = type != nil ? Int(type!.typeID) : nil
		controller.dismiss(animated: true) {
			guard let modules = self.modules else {return}
			modules.first?.engine?.perform {
				for module in modules {
					module.charge = typeID != nil ? NCFittingCharge(typeID: typeID!) : nil
				}
			}
		}
	}
	
	private func reload() {
		guard let modules = self.modules else {return}
		guard let module = modules.first else {return}
		guard let type = self.type else {return}
		
		var sections = [TreeNode]()
		
		let hullType = self.hullType
		let count = modules.count
		
		
		module.engine?.performBlockAndWait {
			
			let route: Route?
			
			if (type.variations?.count ?? 0) > 0 || (type.parentType?.variations?.count ?? 0) > 0 {
				route = Router.Fitting.Variations(type: type) { [weak self] (controller, type) in
					let typeID = Int(type.typeID)
					controller.dismiss(animated: true) {
						guard let modules = self?.modules else {return}
						guard let module = modules.first else {return}
						module.engine?.perform {
							guard let ship = module.owner as? NCFittingShip else {return}
							let charge = module.charge
							var out = [NCFittingModule]()
							for module in modules {
								if let m = ship.replaceModule(module: module, typeID: typeID) {
									m.charge = charge
									out.append(m)
								}
							}
							self?.modules = out
						}
					}
				}
			}
			else {
				route = Router.Database.TypeInfo(module)
			}
			

			var rows: [TreeNode] = [NCFittingModuleInfoRow(module: module, type: type, count: modules.count, route: route)]
			if module.canHaveState(.online) {
				rows.append(NCFittingModuleStateRow(modules: modules))
			}
			sections.append(DefaultTreeSection(nodeIdentifier: "Module",
			                                   title: NSLocalizedString("Module", comment: "").uppercased(),
			                                   children: rows))
			
			
			let chargeGroups = module.chargeGroups
			if chargeGroups.count > 0 {
				
				let ammoRoute = Router.Fitting.Ammo(category: self.chargeCategory!, modules: modules) { [weak self] (controller, type) in
					self?.setAmmo(controller: controller, type: type)
				}

				let charges = module.charges
				let charge = module.charge
				let row: TreeNode
				if let charge = charge, let type = NCDatabase.sharedDatabase?.invTypes[charge.typeID] {
					row = NCFittingChargeRow(type: type, charges: charges, route: ammoRoute)
				}
				else {
					row = NCActionRow(title: NSLocalizedString("Select Ammo", comment: "").uppercased(),  route: ammoRoute)
				}
				let section = DefaultTreeSection(nodeIdentifier: "Charge", title: NSLocalizedString("Charge", comment: "").uppercased(), children: [row])
				sections.append(section)
			}
			
			if module.requireTarget && ((module.owner?.owner?.owner as? NCFittingGang)?.pilots.count ?? 0) > 1 {
				let row: TreeRow
				let route = Router.Fitting.Targets(modules: modules, completionHandler: { (controller, target) in
					controller.dismiss(animated: true, completion: { 
						guard let modules = self.modules else {return}
						modules.first?.engine?.perform {
							for module in modules {
								module.target = target
							}
						}
					})
				})
				if let target = module.target?.owner as? NCFittingCharacter {
					row = NCFleetMemberRow(pilot: target, route: route)
				}
				else {
					row = NCActionRow(prototype: Prototype.NCActionTableViewCell.default, title: NSLocalizedString("Select Target", comment: "").uppercased(), route: route)
				}
				sections.append(DefaultTreeSection(nodeIdentifier: "Target", title: NSLocalizedString("Target", comment: "").uppercased(), children: [row]))
			}

			if module.dps.total > 0 {
				let row = NCFittingModuleDamageChartRow(module: module, count: modules.count)
				row.hullType = hullType
				sections.append(DefaultTreeSection(nodeIdentifier: "DPS", title: NSLocalizedString("DPS", comment: "").uppercased() + ": \(NCUnitFormatter.localizedString(from: module.dps.total * Double(count), unit: .none, style: .full))", children: [row]))
			}
		}
		
		if treeController.content == nil {
			let root = TreeNode()
			root.children = sections
			treeController.content = root
		}
		else {
			treeController.content?.children = sections
		}
	}
}
