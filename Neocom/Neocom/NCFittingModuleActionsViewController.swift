//
//  NCFittingModuleActionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 31.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingModuleStateRow: TreeRow {
	let module: NCFittingModule
	let states: [NCFittingModuleState]
	
	init(module: NCFittingModule) {
		self.module = module
		
		let states: [NCFittingModuleState] = [.offline, .online, .active, .overloaded]
		self.states = states.filter {module.canHaveState($0)}
		
		super.init(cellIdentifier: "NCFittingModuleStateTableViewCell")
		
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
		
		module.engine?.perform {
			let state = self.module.state
			DispatchQueue.main.async {
				if let i = self.states.index(of: state) {
					cell.segmentedControl?.selectedSegmentIndex = i
				}
			}
		}
	}
	

	override var hashValue: Int {
		return module.hashValue
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
			super.init(cellIdentifier: "NCFittingModuleInfoTableViewCell", route: route, accessoryButtonRoute: Router.Database.TypeInfo(type))
		}
		else {
			super.init(cellIdentifier: "NCDefaultTableViewCell", route: route, accessoryButtonRoute: Router.Database.TypeInfo(type))
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
		super.init(type: type, route: route, accessoryButtonRoute: Router.Database.TypeInfo(type))
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
		guard let ship = self.modules?.first?.owner as? NCFittingShip else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[ship.typeID]?.hullType
	}()

	var chargeCategory: NCDBDgmppItemCategory? {
		return self.type?.dgmppItem?.charge
	}
	
	var chargeSection: DefaultTreeSection?

	
	@IBOutlet var treeController: TreeController!
	
	private var observer: NSObjectProtocol?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//navigationController?.preferredContentSize = CGSize(width: view.bounds.size.width, height: 320)

		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		reload()
		tableView.layoutIfNeeded()
		var size = tableView.contentSize
		size.height += tableView.contentInset.top
		size.height += tableView.contentInset.bottom
		navigationController?.preferredContentSize = size

		if let module = modules?.first, observer == nil {
			observer = NotificationCenter.default.addObserver(forName: .NCFittingEngineDidUpdate, object: module.engine, queue: nil) { [weak self] (note) in
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
	
	@IBAction func onChangeState(_ sender: UISegmentedControl) {
		guard let cell = sender.ancestor(of: NCFittingModuleStateTableViewCell.self) else {return}
		guard let node = cell.object as? NCFittingModuleStateRow else {return}
		guard let modules = self.modules else {return}
		let state = node.states[sender.selectedSegmentIndex]
		modules.first?.engine?.perform {
			for module in modules {
				module.preferredState = state
			}
			//self.module?.preferredState = state
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? TreeRow else {return}
		guard let route = node.route else {return}
		route.perform(source: self, view: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let node = node as? TreeRow else {return}
		guard let route = node.accessoryButtonRoute else {return}
		route.perform(source: self, view: treeController.cell(for: node))
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
				
				let ammoRoute = Router.Fitting.Ammo(category: self.chargeCategory!) { [weak self] (controller, type) in
					self?.setAmmo(controller: controller, type: type)
				}

				
				let row = DefaultTreeRow(cellIdentifier: "NCDefaultTableViewCell", title: NSLocalizedString("Select Ammo", comment: ""),  route: ammoRoute)
				self.chargeSection?.children = [row]

			})]
		}
		return nil
	}
	
	//MARK: Private
	
	private func setAmmo(controller: NCFittingAmmoViewController, type: NCDBInvType) {
		let typeID = Int(type.typeID)
		controller.dismiss(animated: true) {
			guard let modules = self.modules else {return}
			modules.first?.engine?.perform {
				for module in modules {
					module.charge = NCFittingCharge(typeID: typeID)
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
				route = Router.Database.TypeInfo(type)
			}
			
			sections.append(NCFittingModuleInfoRow(module: module, type: type, count: modules.count, route: route))
			
			
			let chargeGroups = module.chargeGroups
			if chargeGroups.count > 0 {
				
				let ammoRoute = Router.Fitting.Ammo(category: self.chargeCategory!) { [weak self] (controller, type) in
					self?.setAmmo(controller: controller, type: type)
				}

				let charges = module.charges
				let charge = module.charge
				let row: TreeNode
				if let charge = charge, let type = NCDatabase.sharedDatabase?.invTypes[charge.typeID] {
					row = NCFittingChargeRow(type: type, charges: charges, route: ammoRoute)
				}
				else {
					row = DefaultTreeRow(cellIdentifier: "NCDefaultTableViewCell", title: NSLocalizedString("Select Ammo", comment: ""),  route: ammoRoute)
				}
				let section = DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Charge", title: NSLocalizedString("Charge", comment: "").uppercased(), children: [row])
				sections.append(section)
			}
			
			if module.canHaveState(.online) {
				sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "State", title: NSLocalizedString("State", comment: "").uppercased(), children: [NCFittingModuleStateRow(module: module)]))
			}

			if module.dps.total > 0 {
				let row = NCFittingModuleDamageChartRow(module: module, count: modules.count)
				row.hullType = hullType
				sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "DPS", title: NSLocalizedString("DPS", comment: "").uppercased() + ": \(NCUnitFormatter.localizedString(from: module.dps.total * Double(count), unit: .none, style: .full))", children: [row]))
			}
		}
		
		if treeController.rootNode == nil {
			let root = TreeNode()
			root.children = sections
			treeController.rootNode = root
		}
		else {
			treeController.rootNode?.children = sections
		}
	}
}
