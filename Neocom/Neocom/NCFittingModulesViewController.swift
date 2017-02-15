//
//  NCFittingModulesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

class NCFittingModuleRow: TreeRow {
	lazy var type: NCDBInvType? = {
		guard let module = self.modules.first else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[module.typeID]
	}()
	lazy var chargeType: NCDBInvType? = {
		guard let charge = self.charge else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[charge.typeID]
	}()
	
	let modules: [NCFittingModule]
	let charge: NCFittingCharge?
	let slot: NCFittingModuleSlot
	let state: NCFittingModuleState
	let isEnabled: Bool
	let hasTarget: Bool
	
	init(modules: [NCFittingModule]) {
		self.modules = modules
		let module = modules.first
		self.charge = module?.charge
		self.slot = module?.slot ?? .unknown
		self.state = module?.state ?? .unknown
		self.isEnabled = module?.isEnabled ?? true
		self.hasTarget = module?.target != nil
		super.init(cellIdentifier: module?.isDummy == true ? "NCDefaultTableViewCell" : "ModuleCell")
	}
	
	override func changed(from: TreeNode) -> Bool {
		guard let from = from as? NCFittingModuleRow else {return false}
		subtitle = from.subtitle
		return modules.first?.isDummy == false
	}
	
	var needsUpdate: Bool = true
	var subtitle: NSAttributedString?
	
	override func configure(cell: UITableViewCell) {
		let module = modules.first
		if module?.isDummy == true {
			guard let cell = cell as? NCDefaultTableViewCell else {return}
			cell.object = modules
			cell.iconView?.image = slot.image
			cell.titleLabel?.text = slot.title
		}
		else {
			guard let cell = cell as? NCFittingModuleTableViewCell else {return}
			cell.object = modules
			cell.titleLabel?.textColor = isEnabled ? .white : .red

			if modules.count > 1 {
				cell.titleLabel?.attributedText = (type?.typeName ?? "") + " " + "x\(modules.count)" * [NSForegroundColorAttributeName: UIColor.caption]
			}
			else {
				cell.titleLabel?.text = type?.typeName
			}
			cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.stateView?.image = state.image
			cell.subtitleLabel?.attributedText = subtitle
			cell.targetIconView.image = hasTarget ? #imageLiteral(resourceName: "targets") : nil
			
			cell.subtitleLabel?.superview?.isHidden = subtitle == nil || subtitle?.length == 0
			
			if needsUpdate {
				let font = cell.subtitleLabel!.font!

				let chargeName = chargeType?.typeName
				let chargeImage = chargeType?.icon?.image?.image
				guard let module = module else {return}

				module.engine?.perform {
					guard let ship = module.owner as? NCFittingShip else {return}
					let string = NSMutableAttributedString()
					if let chargeName = chargeName  {
						var s = NSAttributedString(image: chargeImage, font: font) + " \(chargeName)"
						if module.charges > 0 {
							s = s + " x\(module.charges)" * [NSForegroundColorAttributeName: UIColor.caption]
						}
						string.appendLine(s)
					}
					let optimal = module.maxRange
					let falloff = module.falloff
					let lifeTime = module.lifeTime
					let cycleTime = module.cycleTime
					
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
					
					let signature = ship.attributes[NCDBAttributeID.signatureRadius.rawValue]?.initialValue ?? 0
					let accuracy = module.accuracy(targetSignature: signature)

					if accuracy != .none {
						let accuracyScore = module.accuracyScore
						let angularVelocity = module.angularVelocity(targetSignature: signature)
						
						let orbitRadius = ship.orbitRadius(angularVelocity: angularVelocity)

						let color = accuracy.color
						
						let accuracy = NCUnitFormatter.localizedString(from: accuracyScore, unit: .none, style: .full) * [NSForegroundColorAttributeName: UIColor.caption]
						let range = NCUnitFormatter.localizedString(from: orbitRadius, unit: .custom(NSLocalizedString("+ m", comment: "meter"), false), style: .full) * [NSForegroundColorAttributeName: color]
						let s = NSAttributedString(image: #imageLiteral(resourceName: "tracking"), font: font) + " \(NSLocalizedString("accuracy", comment: "")): " + accuracy + " (" + NSAttributedString(image: #imageLiteral(resourceName: "targetingRange"), font: font) + " " + range + " )"
						
						string.appendLine(s)
					}
					if cycleTime > 0 {
						let s = NSAttributedString(image: #imageLiteral(resourceName: "dps"), font: font) + " \(NSLocalizedString("rate of fire", comment: "")): " + NCTimeIntervalFormatter.localizedString(from: cycleTime, precision: .seconds) * [NSForegroundColorAttributeName: UIColor.caption]
						string.appendLine(s)
					}
					
					if lifeTime > 0 {
						let s = NSAttributedString(image: #imageLiteral(resourceName: "overheated"), font: font) + " \(NSLocalizedString("lifetime", comment: "")): " + NCTimeIntervalFormatter.localizedString(from: lifeTime, precision: .seconds) * [NSForegroundColorAttributeName: UIColor.caption]
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
	}
	
	override var hashValue: Int {
		return modules.first?.hashValue ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingModuleRow)?.hashValue == hashValue
	}
	
}

class NCFittingModuleSection: TreeSection {
	let slot: NCFittingModuleSlot
	let grouped: Bool
	
	init(slot: NCFittingModuleSlot, children: [NCFittingModuleRow], grouped: Bool) {
		self.slot = slot
		self.grouped = grouped
		super.init(cellIdentifier: "NCFittingSlotHeaderTableViewCell")
		self.children = children
	}
	
	override var isExpandable: Bool {
		return false
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingSlotHeaderTableViewCell else {return}
		cell.iconView?.image = slot.image
		cell.titleLabel?.text = slot.title?.uppercased()
		let title = grouped ? NSLocalizedString("UNGROUP", comment: "") : NSLocalizedString("GROUP", comment: "")
		cell.groupButton?.setTitle(title, for: .normal)
	}
	
	override var hashValue: Int {
		return slot.rawValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingModuleSection)?.hashValue == hashValue
	}
	
	override func changed(from: TreeNode) -> Bool {
		return (from as? NCFittingModuleSection)?.grouped != grouped
	}

}


class NCFittingModulesViewController: UIViewController, TreeControllerDelegate {
	@IBOutlet weak var treeController: TreeController!
	@IBOutlet weak var tableView: UITableView!

	@IBOutlet weak var powerGridLabel: NCResourceLabel!
	@IBOutlet weak var cpuLabel: NCResourceLabel!
	@IBOutlet weak var calibrationLabel: NCResourceLabel!
	@IBOutlet weak var turretsLabel: UILabel!
	@IBOutlet weak var launchersLabel: UILabel!
	
	var engine: NCFittingEngine? {
		return (parent as? NCShipFittingViewController)?.engine
	}
	
	var fleet: NCFittingFleet? {
		return (parent as? NCShipFittingViewController)?.fleet
	}
	
	var typePickerViewController: NCTypePickerViewController? {
		return (parent as? NCShipFittingViewController)?.typePickerViewController
	}
	
	var grouping = [NCFittingModuleSlot: Bool]()
	
	private var observer: NSObjectProtocol?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		//treeController.childrenKeyPath = "children"
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		powerGridLabel.unit = .megaWatts
		cpuLabel.unit = .teraflops
		calibrationLabel.unit = .none
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
	
	@IBAction func onChangeGroup(_ sender: UIButton) {
		guard let cell = sender.ancestor(of: NCFittingSlotHeaderTableViewCell.self) else {return}
		guard let node = treeController.node(for: cell) as? NCFittingModuleSection else {return}
		self.grouping[node.slot] = !node.grouped
		reload()
	}
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let item = node as? NCFittingModuleRow else {return}
		guard let pilot = fleet?.active else {return}
		//guard let ship = ship else {return}
		guard let typePickerViewController = typePickerViewController else {return}
		let module = item.modules.first
		if module?.isDummy == true {
			let category: NCDBDgmppItemCategory?
			switch item.slot {
			case .hi:
				category = NCDBDgmppItemCategory.category(categoryID: .hi, subcategory: NCDBCategoryID.module.rawValue)
			case .med:
				category = NCDBDgmppItemCategory.category(categoryID: .med, subcategory: NCDBCategoryID.module.rawValue)
			case .low:
				category = NCDBDgmppItemCategory.category(categoryID: .low, subcategory: NCDBCategoryID.module.rawValue)
//			case .rig:
//				category = NCDBDgmppItemCategory.category(categoryID: .rig, subcategory: ship.rigSize)
			//case .subsystem:
			//	category = NCDBDgmppItemCategory.category(categoryID: .subsystem, subcategory: ship.rigSize)
			default:
				return
			}
			typePickerViewController.category = category
			typePickerViewController.completionHandler = { [weak typePickerViewController] type in
				let typeID = Int(type.typeID)
				self.engine?.perform {
					_ = pilot.ship?.addModule(typeID: typeID)
				}
				typePickerViewController?.dismiss(animated: true)
			}
			present(typePickerViewController, animated: true)
		}
		else {
			performSegue(withIdentifier: "NCFittingModuleActionsViewController", sender: treeController.cell(for: node))
		}
	}
	
	//MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCFittingModuleActionsViewController"?:
			guard let controller = (segue.destination as? UINavigationController)?.topViewController as? NCFittingModuleActionsViewController else {return}
			guard let cell = sender as? NCFittingModuleTableViewCell else {return}
			controller.modules = cell.object as? [NCFittingModule]
		default:
			break
		}
	}
	
	//MARK: - Private
	
	private func update() {
		engine?.perform {
			guard let ship = self.fleet?.active?.ship else {return}
			let powerGrid = (ship.powerGridUsed, ship.totalPowerGrid)
			let cpu = (ship.cpuUsed, ship.totalCPU)
			let calibration = (ship.calibrationUsed, ship.totalCalibration)
			let turrets = (ship.usedHardpoints(.turret), ship.totalHardpoints(.turret))
			let launchers = (ship.usedHardpoints(.launcher), ship.totalHardpoints(.launcher))

			DispatchQueue.main.async {
				self.powerGridLabel.value = powerGrid.0
				self.powerGridLabel.maximumValue = powerGrid.1
				self.cpuLabel.value = cpu.0
				self.cpuLabel.maximumValue = cpu.1
				self.calibrationLabel.value = calibration.0
				self.calibrationLabel.maximumValue = calibration.1
				
				self.turretsLabel.text = "\(turrets.0)/\(turrets.1)"
				self.launchersLabel.text = "\(launchers.0)/\(launchers.1)"
				self.turretsLabel.textColor = turrets.0 > turrets.1 ? .red : .white
				self.launchersLabel.textColor = launchers.0 > launchers.1 ? .red : .white

			}
		}
	}
	
	private func reload() {
		let grouping = self.grouping
		engine?.perform {
			guard let ship = self.fleet?.active?.ship else {return}
			
			var sections = [NCFittingModuleSection]()
			for slot in [NCFittingModuleSlot.hi, NCFittingModuleSlot.med, NCFittingModuleSlot.low, NCFittingModuleSlot.rig, NCFittingModuleSlot.subsystem, NCFittingModuleSlot.service, NCFittingModuleSlot.mode] {
				let grouped = grouping[slot] ?? false
				let rows: [NCFittingModuleRow]
				if grouped {
					var groups = [[NCFittingModule]]()
					for module in ship.modules(slot: slot) {
						let charge = module.charge?.typeID ?? 0
						let state = module.state
						let type = module.typeID
						
						if let index = groups.index(where: { i in
							guard let m = i.first else {return false}
							return type == m.typeID && state == m.state && charge == (m.charge?.typeID ?? 0)
						}) {
							groups[index].append(module)
						}
						else {
							groups.append([module])
						}
						
					}
					rows = groups.flatMap({ (modules) -> NCFittingModuleRow? in
						return NCFittingModuleRow(modules: modules)
					})
				}
				else {
					rows = ship.modules(slot: slot).flatMap({ (module) -> NCFittingModuleRow? in
						return NCFittingModuleRow(modules: [module])
					})
				}
				if (rows.count > 0) {
					sections.append(NCFittingModuleSection(slot: slot, children: rows, grouped: grouping[slot] ?? false))
				}
			}

			DispatchQueue.main.async {
				if self.treeController.rootNode == nil {
					self.treeController.rootNode = TreeNode()
				}
				self.treeController.rootNode?.children = sections
			}
		}
		update()
	}
}
