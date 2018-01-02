//
//  NCFittingModulesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import CloudData
import Dgmpp

class NCFittingModuleRow: TreeRow {
	
	lazy var type: NCDBInvType? = {
		return self.modules.first?.type
	}()
	
	lazy var chargeType: NCDBInvType? = {
		return self.modules.first?.charge?.type
	}()
	
	let modules: [DGMModule]
	let slot: DGMModule.Slot
	
	init(modules: [DGMModule], slot: DGMModule.Slot) {
		self.modules = modules
		self.slot = slot
		super.init(prototype: modules.isEmpty ? Prototype.NCDefaultTableViewCell.compact : Prototype.NCFittingModuleTableViewCell.default)
	}
	
	override func update(from node: TreeNode) {
		super.update(from: node)
		guard let from = node as? NCFittingModuleRow else {return}
		subtitle = from.subtitle
	}

	var needsUpdate: Bool = true
	var subtitle: NSAttributedString?

	override func configure(cell: UITableViewCell) {
		
		if let module = modules.first {
			guard let cell = cell as? NCFittingModuleTableViewCell else {return}

			let hasTarget = module.target != nil
			let hasStates = slot != .rig && slot != .service && slot != .subsystem && slot != .mode
			
			
			cell.object = modules
			cell.titleLabel?.textColor = module.isFail ? .red : .white
			
			if modules.count > 1 {
				cell.titleLabel?.attributedText = (type?.typeName ?? "") + " " + "x\(modules.count)" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
			}
			else {
				cell.titleLabel?.text = type?.typeName
			}
			cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.stateView?.image = module.state.image
			cell.stateView?.isHidden = !hasStates
			cell.targetIconView.image = hasTarget ? #imageLiteral(resourceName: "targets") : nil
			
			//			cell.subtitleLabel?.superview?.isHidden = subtitle == nil || subtitle?.length == 0
			
			if needsUpdate {
				let font = cell.subtitleLabel!.font!
				
				let chargeName = chargeType?.typeName
				let chargeImage = chargeType?.icon?.image?.image
				
				//				module.engine?.perform {
				guard let ship = module.parent as? DGMShip else {return}
				let string = NSMutableAttributedString()
				if let chargeName = chargeName  {
					var s = NSAttributedString(image: chargeImage, font: font) + " \(chargeName)"
					if module.charges > 0 {
						s = s + " x\(module.charges)" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
					}
					string.appendLine(s)
				}
				let optimal = module.optimal
				let falloff = module.falloff
				let lifeTime = module.lifeTime
				let cycleTime = module.cycleTime
				
				if optimal > 0 {
					let s: NSAttributedString
					let attr = [NSAttributedStringKey.foregroundColor: UIColor.caption]
					let image = NSAttributedString(image: #imageLiteral(resourceName: "targetingRange"), font: font)
					if falloff > 0 {
						s = image + " \(NSLocalizedString("optimal + falloff", comment: "")): " + (NCUnitFormatter.localizedString(from: optimal, unit: .meter, style: .full) + " + " + NCUnitFormatter.localizedString(from: falloff, unit: .meter, style: .full)) * attr
					}
					else {
						s =  image + " \(NSLocalizedString("optimal", comment: "")): " + NCUnitFormatter.localizedString(from: optimal, unit: .meter, style: .full) * attr
					}
					string.appendLine(s)
				}
				
				let signature = ship[NCDBAttributeID.signatureRadius.rawValue]?.initialValue ?? 0
				let accuracy = module.accuracy(targetSignature: signature)
				
				if accuracy != .none {
					let accuracyScore = module.accuracyScore
					let angularVelocity = module.angularVelocity(targetSignature: signature)
					
					let orbitRadius = ship.orbitRadius(angularVelocity: angularVelocity)
					
					let color = accuracy.color
					
					let accuracy = NCUnitFormatter.localizedString(from: accuracyScore, unit: .none, style: .full) * [NSAttributedStringKey.foregroundColor: UIColor.caption]
					let range = NCUnitFormatter.localizedString(from: orbitRadius, unit: .custom(NSLocalizedString("+ m", comment: "meter"), false), style: .full) * [NSAttributedStringKey.foregroundColor: color]
					let s = NSAttributedString(image: #imageLiteral(resourceName: "tracking"), font: font) + " \(NSLocalizedString("accuracy", comment: "")): " + accuracy + " (" + NSAttributedString(image: #imageLiteral(resourceName: "targetingRange"), font: font) + " " + range + " )"
					
					string.appendLine(s)
				}
				if cycleTime > 0 {
					let s = NSAttributedString(image: #imageLiteral(resourceName: "dps"), font: font) + " \(NSLocalizedString("rate of fire", comment: "")): " + NCTimeIntervalFormatter.localizedString(from: cycleTime, precision: .seconds) * [NSAttributedStringKey.foregroundColor: UIColor.caption]
					string.appendLine(s)
				}
				
				if lifeTime > 0 {
					let s = NSAttributedString(image: #imageLiteral(resourceName: "overheated"), font: font) + " \(NSLocalizedString("lifetime", comment: "")): " + NCTimeIntervalFormatter.localizedString(from: lifeTime, precision: .seconds) * [NSAttributedStringKey.foregroundColor: UIColor.caption]
					string.appendLine(s)
				}
				
				needsUpdate = false
				subtitle = string
			}
			cell.subtitleLabel?.attributedText = subtitle

		}
		else {
			guard let cell = cell as? NCDefaultTableViewCell else {return}
			cell.object = modules
			cell.iconView?.image = slot.image
			cell.titleLabel?.text = slot.title
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
	let slot: DGMModule.Slot
	let grouped: Bool
	
	init(slot: DGMModule.Slot, children: [NCFittingModuleRow], grouped: Bool) {
		self.slot = slot
		self.grouped = grouped
		super.init(prototype: Prototype.NCFittingSlotHeaderTableViewCell.default)
		self.children = children
		isExpandable = false
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
	
}


class NCFittingModulesViewController: UIViewController, TreeControllerDelegate, NCFittingEditorPage {
	@IBOutlet weak var treeController: TreeController!
	@IBOutlet weak var tableView: UITableView!

	@IBOutlet weak var powerGridLabel: NCResourceLabel!
	@IBOutlet weak var cpuLabel: NCResourceLabel!
	@IBOutlet weak var calibrationLabel: NCResourceLabel!
	@IBOutlet weak var turretsLabel: UILabel!
	@IBOutlet weak var launchersLabel: UILabel!
	
	var grouping = [DGMModule.Slot: Bool]()
	
	private var observer: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCFittingModuleTableViewCell.default
		                    ])
		//treeController.childrenKeyPath = "children"
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.tableView = tableView
		treeController.delegate = self
		
		powerGridLabel.unit = .megaWatts
		cpuLabel.unit = .teraflops
		calibrationLabel.unit = .none
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if self.treeController.content == nil {
			self.treeController.content = TreeNode()
			DispatchQueue.main.async {
				self.reload()
			}
		}
	
		if observer == nil {
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingFleetDidUpdate, object: fleet, queue: nil) { [weak self] (note) in
				guard self?.view.window != nil else {
					self?.treeController.content = nil
					return
				}
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
		treeController.deselectCell(for: node, animated: true)
		guard let item = node as? NCFittingModuleRow else {return}
		guard let pilot = fleet?.active else {return}
		guard let ship = pilot.ship else {return}
		guard let typePickerViewController = typePickerViewController else {return}
		let socket = (node.parent as? NCFittingModuleSection)?.grouped == true ? -1 : node.parent?.children.index(of: item) ?? -1
		let isStructure = ship is DGMStructure

		if item.modules.isEmpty {
			let category: NCDBDgmppItemCategory?
			switch item.slot {
			case .hi:
				category = NCDBDgmppItemCategory.category(categoryID: .hi, subcategory: isStructure ? NCDBCategoryID.structureModule.rawValue : NCDBCategoryID.module.rawValue)
			case .med:
				category = NCDBDgmppItemCategory.category(categoryID: .med, subcategory: isStructure ? NCDBCategoryID.structureModule.rawValue : NCDBCategoryID.module.rawValue)
			case .low:
				category = NCDBDgmppItemCategory.category(categoryID: .low, subcategory: isStructure ? NCDBCategoryID.structureModule.rawValue : NCDBCategoryID.module.rawValue)
			case .rig:
				category = NCDBDgmppItemCategory.category(categoryID: isStructure ? .structureRig : .rig, subcategory: ship.rigSize.rawValue)
			case .subsystem:
				guard let raceID = pilot.ship?.raceID, let race = NCDatabase.sharedDatabase?.chrRaces[raceID.rawValue] else {return}
				category = NCDBDgmppItemCategory.category(categoryID: .subsystem, subcategory: nil, race: race)
			case .service:
				category = NCDBDgmppItemCategory.category(categoryID: .service, subcategory: NCDBCategoryID.structureModule.rawValue)
			case .mode:
				category = NCDBDgmppItemCategory.category(categoryID: .mode, subcategory: ship.typeID)
			default:
				return
			}
			let isGrouped = grouping[item.slot] == true

			typePickerViewController.category = category
			typePickerViewController.completionHandler = { [weak typePickerViewController, weak self] (_, type) in
				let typeID = Int(type.typeID)
				let n = isGrouped ? max(ship.freeSlots(item.slot), 1) : 1
				do {
					for _ in 0..<n {
						try ship.add(DGMModule(typeID: typeID), socket: socket)
					}
				}
				catch {
				}
				NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
				if self?.editorViewController?.traitCollection.horizontalSizeClass == .compact || self?.traitCollection.userInterfaceIdiom == .phone {
					typePickerViewController?.dismiss(animated: true)
				}
			}
			Route(kind: .popover, viewController: typePickerViewController).perform(source: self, sender: treeController.cell(for: node))
		}
		else {
			guard let fleet = fleet else {return}
			Router.Fitting.ModuleActions(item.modules, fleet: fleet).perform(source: self, sender: treeController.cell(for: item))
		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCFittingModuleRow else {return nil}
		
		let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { [weak self] (_, _) in
			let modules = node.modules
			guard let ship = modules.first?.parent as? DGMShip else {return}
			modules.forEach {
				ship.remove($0)
			}
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
		}
		
		return [deleteAction]
	}
	
	//MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCFittingModuleActionsViewController"?:
			guard let controller = (segue.destination as? UINavigationController)?.topViewController as? NCFittingModuleActionsViewController else {return}
			guard let cell = sender as? NCFittingModuleTableViewCell else {return}
			controller.modules = cell.object as? [DGMModule]
		default:
			break
		}
	}
	
	//MARK: - Private
	
	private func update() {
		guard let pilot = self.fleet?.active else {return}
		guard let ship = pilot.ship else {return}
		
		powerGridLabel.value = ship.usedPowerGrid
		powerGridLabel.maximumValue = ship.totalPowerGrid
		cpuLabel.value = ship.usedCPU
		cpuLabel.maximumValue = ship.totalCPU
		calibrationLabel.value = ship.usedCalibration
		calibrationLabel.maximumValue = ship.totalCalibration
		
		let turrets = (ship.usedHardpoints(.turret), ship.totalHardpoints(.turret))
		let launchers = (ship.usedHardpoints(.launcher), ship.totalHardpoints(.launcher))

		turretsLabel.text = "\(turrets.0)/\(turrets.1)"
		launchersLabel.text = "\(launchers.0)/\(launchers.1)"
		turretsLabel.textColor = turrets.0 > turrets.1 ? .red : .white
		launchersLabel.textColor = launchers.0 > launchers.1 ? .red : .white
	}
	
	private func reload() {
		let grouping = self.grouping
		guard let pilot = fleet?.active else {return}
		guard let ship = pilot.ship else {return}
		
		var sections = [NCFittingModuleSection]()
		for slot in [DGMModule.Slot.hi, DGMModule.Slot.med, DGMModule.Slot.low, DGMModule.Slot.rig, DGMModule.Slot.subsystem, DGMModule.Slot.service, DGMModule.Slot.mode] {
			let grouped = grouping[slot] ?? false
			let rows: [NCFittingModuleRow]
			if grouped {
				var groups = [[DGMModule]]()
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
				if ship.freeSlots(slot) > 0 {
					groups.append([])
				}
				rows = groups.flatMap({ (modules) -> NCFittingModuleRow? in
					return NCFittingModuleRow(modules: modules, slot: slot)
				})
			}
			else {
				var socket = 0
				var r = [NCFittingModuleRow]()
				for module in ship.modules(slot: slot) {
					r.append(contentsOf: (socket..<module.socket).map{ _ in
						return NCFittingModuleRow(modules: [], slot: slot)
					})
					r.append(NCFittingModuleRow(modules: [module], slot: slot))
					socket = module.socket + 1
				}
				r.append(contentsOf: (socket..<max(ship.totalSlots(slot), socket)).map{ _ in
					return NCFittingModuleRow(modules: [], slot: slot)
				})
				
				rows = r
			}
			if (rows.count > 0) {
				sections.append(NCFittingModuleSection(slot: slot, children: rows, grouped: grouping[slot] ?? false))
			}
		}
		
		treeController.content?.children = sections
		update()
	}
}
