//
//  NCFittingModulesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

class NCFittingModuleRow: NCTreeRow {
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.module.typeID]
	}()
	
	let module: NCFittingModule
	let slot: NCFittingModuleSlot
	
	init(module: NCFittingModule) {
		self.module = module
		self.slot = module.slot
		super.init(cellIdentifier: module.isDummy ? "Cell" : "ModuleCell")
	}
	
	override func configure(cell: UITableViewCell) {
		if module.isDummy {
			guard let cell = cell as? NCDefaultTableViewCell else {return}
			cell.iconView?.image = slot.image
			cell.titleLabel?.text = slot.title
		}
		else {
			guard let cell = cell as? NCFittingModuleTableViewCell else {return}
			cell.titleLabel?.text = type?.typeName
			cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.stateView?.image = module.state.image
			cell.subtitleLabel?.text = nil
		}
	}
}

class NCFittingModuleSection: NCTreeSection {
	let slot: NCFittingModuleSlot
	
	init(slot: NCFittingModuleSlot, children: [NCFittingModuleRow]) {
		self.slot = slot
		super.init(cellIdentifier: "HeaderCell", title: "Title", children: children)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.iconView?.image = slot.image
		cell.titleLabel?.text = slot.title?.uppercased()
	}
}


class NCFittingModulesViewController: UIViewController, NCTreeControllerDelegate {
	@IBOutlet weak var treeController: NCTreeController!
	@IBOutlet weak var tableView: UITableView!

	@IBOutlet weak var powerGridLabel: NCResourceLabel!
	@IBOutlet weak var cpuLabel: NCResourceLabel!
	@IBOutlet weak var calibrationLabel: NCResourceLabel!
	@IBOutlet weak var turretsLabel: UILabel!
	@IBOutlet weak var launchersLabel: UILabel!
	
	var engine: NCFittingEngine? {
		return (parent as? NCShipFittingViewController)?.engine
	}
	
	var fleet: NCFleet? {
		return (parent as? NCShipFittingViewController)?.fleet
	}
	
	var typePickerViewController: NCTypePickerViewController? {
		return (parent as? NCShipFittingViewController)?.typePickerViewController
	}
	
	private var obsever: NSObjectProtocol?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		treeController.childrenKeyPath = "children"
		treeController.delegate = self
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		powerGridLabel.unit = .megaWatts
		cpuLabel.unit = .teraflops
		calibrationLabel.unit = .none
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		engine?.perform {
			let sections = self.modulesSections
			DispatchQueue.main.async {
				self.treeController.content = sections
				self.treeController.reloadData()
			}
		}
		
		update()
		if obsever == nil {
			obsever = NotificationCenter.default.addObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
				guard let strongSelf = self else {return}
				
				strongSelf.treeController.content = strongSelf.modulesSections
				strongSelf.treeController.reloadData()
				strongSelf.update()
			}
		}
	}
	
	//MARK: - NCTreeControllerDelegate
	
	func treeController(_ treeController: NCTreeController, cellIdentifierForItem item: AnyObject) -> String {
		return (item as! NCTreeNode).cellIdentifier
	}
	
	func treeController(_ treeController: NCTreeController, configureCell cell: UITableViewCell, withItem item: AnyObject) {
		(item as? NCTreeNode)?.configure(cell: cell)
	}
	
	func treeController(_ treeController: NCTreeController, didSelectCell cell: UITableViewCell, withItem item: AnyObject) {
		guard let item = item as? NCFittingModuleRow else {return}
		//guard let ship = ship else {return}
		guard let typePickerViewController = typePickerViewController else {return}
		
		if item.module.isDummy {
			let category: NCDBDgmppItemCategory?
			switch item.module.slot {
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
//				ship.addModule(typeID: Int(type.typeID))
				typePickerViewController?.dismiss(animated: true)
			}
			present(typePickerViewController, animated: true)
		}
	}
	
	func treeController(_ treeController: NCTreeController, isItemExpandable item: AnyObject) -> Bool {
		return false
	}
	
	//MARK: - Private
	
	private var modulesSections: [NCFittingModuleSection] {
		guard let ship = fleet?.active?.ship else {return []}

		var sections = [NCFittingModuleSection]()
		for slot in [NCFittingModuleSlot.hi, NCFittingModuleSlot.med, NCFittingModuleSlot.low, NCFittingModuleSlot.rig, NCFittingModuleSlot.subsystem, NCFittingModuleSlot.service, NCFittingModuleSlot.mode] {
			let rows = ship.modules(slot: slot).flatMap({ (module) -> NCFittingModuleRow? in
				return NCFittingModuleRow(module: module)
			})
			if (rows.count > 0) {
				sections.append(NCFittingModuleSection(slot: slot, children: rows))
			}
		}
		return sections
	}
	
	private func update() {
		engine?.perform {
			guard let ship = self.fleet?.active?.ship else {return}
			let powerGridUsed = ship.powerGridUsed
			let totalPowerGrid = ship.totalPowerGrid
			let cpuUsed = ship.cpuUsed
			let totalCPU = ship.totalCPU
			let calibrationUsed = ship.calibrationUsed
			let totalCalibration = ship.totalCalibration
			
			let turrets = "\(ship.usedHardpoints(.turret))/\(ship.freeHardpoints(.turret))"
			let launchers = "\(ship.usedHardpoints(.launcher))/\(ship.freeHardpoints(.launcher))"
			DispatchQueue.main.async {
				self.powerGridLabel.value = powerGridUsed
				self.powerGridLabel.maximumValue = totalPowerGrid
				self.cpuLabel.value = cpuUsed
				self.cpuLabel.maximumValue = totalCPU
				self.calibrationLabel.value = calibrationUsed
				self.calibrationLabel.maximumValue = totalCalibration
				
				self.turretsLabel.text = turrets
				self.launchersLabel.text = launchers
			}
			
		}
	}
}
