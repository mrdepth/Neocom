//
//  NCFittingModuleActionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 31.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData
import Dgmpp
import EVEAPI
import Futures

class NCFittingModuleStateRow: TreeRow {
	let fleet: NCFittingFleet
	let modules: [DGMModule]
	let states: [DGMModule.State]
	
	init(modules: [DGMModule], fleet: NCFittingFleet) {
		self.modules = modules
		self.fleet = fleet
		let module = modules.first!
		states = module.availableStates
		
		super.init(prototype: Prototype.NCFittingModuleStateTableViewCell.default)
		
	}
	
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
		cell.actionHandler = NCActionHandler(segmentedControl, for: .valueChanged) { [weak self, weak segmentedControl] _ in
			guard let sender = segmentedControl else {return}
			guard let state = self?.states[sender.selectedSegmentIndex] else {return}
			for module in self?.modules ?? [] {
				module.state = state
			}
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)

		}
		
		if let i = self.states.index(of: module.state) {
			cell.segmentedControl?.selectedSegmentIndex = i
		}
	}
	

	override var hash: Int {
		return modules.first?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingModuleStateRow)?.hashValue == hashValue
	}
	
}

class NCFittingModuleInfoRow: TreeRow {
	let module: DGMModule
	let cpu: Double
	let powerGrid: Double
	let capacitor: Double
	let count: Int
	
	let type: NCDBInvType
	
	init(module: DGMModule, type: NCDBInvType, count: Int, route: Route? = nil) {
		self.module = module
		self.count = count
		let cpu = module.cpuUse
		let powerGrid = module.powerGridUse
		let capacitor = module.capUse * DGMSeconds(1)
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
			title = (type.typeName ?? "") + " " + "x\(count)" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
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

	override var hash: Int {
		return module.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingModuleInfoRow)?.hashValue == hashValue
	}
}

class NCFittingChargeRow: NCChargeRow {
	let charges: Int
	init(charge: DGMCharge, type: NCDBInvType, charges: Int, route: Route? = nil) {
		self.charges = charges
		super.init(prototype: Prototype.NCChargeTableViewCell.compact, type: type, route: route, accessoryButtonRoute: Router.Database.TypeInfo(charge))
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		if charges > 0 {
			let title = (type.typeName ?? "") + " x\(charges)" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
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

class NCFittingModuleActionsViewController: NCTreeViewController {
	var fleet: NCFittingFleet?
	var modules: [DGMModule]?
	var type: NCDBInvType? {
		guard let module = self.modules?.first else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[module.typeID]
	}

	lazy var hullType: NCDBDgmppHullType? = {
		guard let module = self.modules?.first else {return nil}
		if let targetTypeID = module.target?.typeID, let hullType = NCDatabase.sharedDatabase?.invTypes[targetTypeID]?.hullType {
			return hullType
		}
		guard let ship = self.modules?.first?.parent as? DGMShip else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[ship.typeID]?.hullType
	}()

	var chargeCategory: NCDBDgmppItemCategory? {
		return self.type?.dgmppItem?.charge
	}
	
	var chargeSection: DefaultTreeSection?

	
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
		guard let modules = self.modules else {return}
		guard let module = modules.first else {return}
		guard let ship = module.parent as? DGMShip else {return}
		for module in modules {
			ship.remove(module)
		}
		self.modules = nil
		self.dismiss(animated: true, completion: nil)
		NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: fleet)
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
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		if node is NCFittingChargeRow {
			return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Unload", comment: "Unload ammo"), handler: { [weak self] (_,_)  in
				guard let modules = self?.modules else {return}
				for module in modules {
					try? module.setCharge(nil)
				}
				
				NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)

				let ammoRoute = Router.Fitting.Ammo(category: self!.chargeCategory!, modules: modules) { [weak self] (controller, type) in
					self?.setAmmo(controller: controller, type: type)
					NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
				}

				let row = NCActionRow(title: NSLocalizedString("Select Ammo", comment: ""),  route: ammoRoute)
				self?.chargeSection?.children = [row]
			})]
		}
		return nil
	}
	
	//MARK: Private
	
	private func setAmmo(controller: NCFittingAmmoViewController, type: NCDBInvType?) {
		let typeID = type != nil ? Int(type!.typeID) : nil
		controller.dismiss(animated: true) {
			guard let modules = self.modules else {return}
			for module in modules {
				try? module.setCharge(typeID != nil ? DGMCharge(typeID: typeID!) : nil)
			}
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self.fleet)
		}
	}
	
	private func reload() {
		guard let fleet = fleet else {return}
		guard let modules = modules else {return}
		guard let module = modules.first else {return}
		guard let type = type else {return}
		
		var sections = [TreeNode]()
		
		let hullType = self.hullType
		let count = modules.count
		
		
		let route: Route?
		
		let hasVariations = (type.variations?.allObjects as? [NCDBInvType])?.filter({$0.dgmppItem != nil}).isEmpty == false || (type.parentType?.variations?.allObjects as? [NCDBInvType])?.filter({$0.dgmppItem != nil}).isEmpty == false
		
		if hasVariations {
			route = Router.Fitting.Variations(type: type) { [weak self] (controller, type) in
				let typeID = Int(type.typeID)
				controller.dismiss(animated: true) {
					guard let modules = self?.modules else {return}
					guard let module = modules.first else {return}
					guard let ship = module.parent as? DGMShip else {return}
					let chargeID = module.charge?.typeID
					var out = [DGMModule]()
					for module in modules {
						do {
							let socket = module.socket
							ship.remove(module)
							let m = try DGMModule(typeID: typeID)
							try ship.add(m, socket: socket)
							if let chargeID = chargeID {
								try m.setCharge(DGMCharge(typeID: chargeID))
							}
							out.append(m)
						}
						catch {
							
						}
					}
					self?.modules = out
					NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
				}
			}
		}
		else {
			route = Router.Database.TypeInfo(module)
		}
		
		
		var rows: [TreeNode] = [NCFittingModuleInfoRow(module: module, type: type, count: modules.count, route: route)]
		if module.canHaveState(.online) {
			rows.append(NCFittingModuleStateRow(modules: modules, fleet: fleet))
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
				row = NCFittingChargeRow(charge: charge, type: type, charges: charges, route: ammoRoute)
			}
			else {
				row = NCActionRow(title: NSLocalizedString("Select Ammo", comment: "").uppercased(),  route: ammoRoute)
			}
			let section = DefaultTreeSection(nodeIdentifier: "Charge", title: NSLocalizedString("Charge", comment: "").uppercased(), children: [row])
			sections.append(section)
		}
		
		if module.requireTarget && ((module.parent?.parent?.parent as? DGMGang)?.pilots.count ?? 0) > 1 {
			let row: TreeRow
			let route = Router.Fitting.Targets(modules: modules, completionHandler: { [weak self] (controller, target) in
				controller.dismiss(animated: true, completion: {
					guard let modules = self?.modules else {return}
					for module in modules {
						module.target = target
					}
					NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
				})
			})
			if let target = module.target?.parent as? DGMCharacter {
				row = NCFleetMemberRow(pilot: target, route: route)
			}
			else {
				row = NCActionRow(prototype: Prototype.NCActionTableViewCell.default, title: NSLocalizedString("Select Target", comment: "").uppercased(), route: route)
			}
			sections.append(DefaultTreeSection(nodeIdentifier: "Target", title: NSLocalizedString("Target", comment: "").uppercased(), children: [row]))
		}
		
		let dps = (module.dps() * DGMSeconds(1)).total
		if dps > 0 {
			let row = NCFittingModuleDamageChartRow(module: module, count: modules.count)
			row.hullType = hullType
			sections.append(DefaultTreeSection(nodeIdentifier: "DPS", title: NSLocalizedString("DPS", comment: "").uppercased() + ": \(NCUnitFormatter.localizedString(from: dps * Double(count), unit: .none, style: .full))", children: [row]))
		}
		
		if treeController?.content == nil {
			treeController?.content = RootNode(sections)
		}
		else {
			treeController?.content?.children = sections
		}
	}
}
