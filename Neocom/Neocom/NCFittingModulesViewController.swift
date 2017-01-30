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
		return NCDatabase.sharedDatabase?.invTypes[self.module.typeID]
	}()
	lazy var chargeType: NCDBInvType? = {
		guard let charge = self.charge else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[charge.typeID]
	}()
	
	let module: NCFittingModule
	let charge: NCFittingCharge?
	let slot: NCFittingModuleSlot
	let state: NCFittingModuleState
	let isEnabled: Bool
	
	init(module: NCFittingModule) {
		self.module = module
		self.charge = module.charge
		self.slot = module.slot
		self.state = module.state
		self.isEnabled = module.isEnabled
		needsUpdate = true
		super.init(cellIdentifier: module.isDummy ? "Cell" : "ModuleCell")
	}
	
	override func changed(from: TreeNode) -> Bool {
		guard let from = from as? NCFittingModuleRow else {return false}
		subtitle = from.subtitle
		return !module.isDummy
	}
	
	var needsUpdate: Bool
	var subtitle: NSAttributedString?
	
	override func configure(cell: UITableViewCell) {
		if module.isDummy {
			guard let cell = cell as? NCDefaultTableViewCell else {return}
			cell.object = module
			cell.iconView?.image = slot.image
			cell.titleLabel?.text = slot.title
		}
		else {
			guard let cell = cell as? NCFittingModuleTableViewCell else {return}
			cell.object = module
			cell.titleLabel?.text = type?.typeName
			cell.titleLabel?.textColor = isEnabled ? .white : .red
			cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.stateView?.image = state.image
			cell.subtitleLabel?.attributedText = subtitle
			
			if needsUpdate {
				let font = cell.subtitleLabel!.font!

				let module = self.module
				let charge = self.charge
				let chargeName = chargeType?.typeName
				let chargeImage = chargeType?.icon?.image?.image
				
				module.engine?.perform {
					let string = NSMutableAttributedString()
					if let chargeName = chargeName  {
						let attachment = NSTextAttachment()
						attachment.image = chargeImage
						attachment.bounds = CGRect(x: 0, y: font.descender, width: font.lineHeight, height: font.lineHeight)
						string.append(NSAttributedString(attachment: attachment))
						string.append(NSAttributedString(string: " \(chargeName) x\(module.charges)"))
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
		return module.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingModuleRow)?.hashValue == hashValue
	}
	
}

class NCFittingModuleSection: TreeSection {
	let slot: NCFittingModuleSlot
	
	init(slot: NCFittingModuleSlot, children: [NCFittingModuleRow]) {
		self.slot = slot
		super.init(cellIdentifier: "HeaderCell")
		self.children = children
	}
	
	override var isExpandable: Bool {
		return false
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.iconView?.image = slot.image
		cell.titleLabel?.text = slot.title?.uppercased()
	}
	
	override var hashValue: Int {
		return slot.rawValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingModuleSection)?.hashValue == hashValue
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
	
	var fleet: NCFleet? {
		return (parent as? NCShipFittingViewController)?.fleet
	}
	
	var typePickerViewController: NCTypePickerViewController? {
		return (parent as? NCShipFittingViewController)?.typePickerViewController
	}
	
	private var obsever: NSObjectProtocol?
	
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
			engine?.perform {
				let sections = self.modulesSections
				DispatchQueue.main.async {
					self.treeController.rootNode = TreeNode()
					self.treeController.rootNode?.children = sections
				}
			}
			update()
		}
	
		if obsever == nil {
			obsever = NotificationCenter.default.addObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
				guard let strongSelf = self else {return}
				
				strongSelf.engine?.perform {
					let sections = strongSelf.modulesSections
					DispatchQueue.main.async {
						strongSelf.treeController.rootNode?.children = sections
						/*let from = strongSelf.treeController.content as? [NCFittingModuleSection]
						strongSelf.treeController.content = sections

						let treeController = strongSelf.treeController
						from?.transition(to: sections, handler: { (old, new, type) in
							switch type {
							case .insert:
								treeController?.insertChildren(IndexSet(integer: new!), ofItem: nil, withRowAnimation: .automatic)
							case .delete:
								treeController?.deleteChildren(IndexSet(integer: old!), ofItem: nil, withRowAnimation: .automatic)
							case .move:
								treeController?.deleteChildren(IndexSet(integer: old!), ofItem: nil, withRowAnimation: .automatic)
								treeController?.insertChildren(IndexSet(integer: new!), ofItem: nil, withRowAnimation: .automatic)
							case .update:
								let section = from?[old!]
								section?.children?.transition(to: sections[new!].children!, handler: { (old, new, type) in
									switch type {
									case .insert:
										treeController?.insertChildren(IndexSet(integer: new!), ofItem: section, withRowAnimation: .automatic)
									case .delete:
										treeController?.deleteChildren(IndexSet(integer: old!), ofItem: section, withRowAnimation: .automatic)
									case .move:
										treeController?.deleteChildren(IndexSet(integer: old!), ofItem: section, withRowAnimation: .automatic)
										treeController?.insertChildren(IndexSet(integer: new!), ofItem: section, withRowAnimation: .automatic)
									case .update:
										//treeController?.reloadRows(items: [section!.children![new!]], rowAnimation: .automatic)
										break
									}
								})
							}
						})*/
						//strongSelf.treeController.reloadData()
					}
				}
				strongSelf.update()
			}
		}
	}
	
	//MARK: - NCTreeControllerDelegate
	
	/*func treeController(_ treeController: NCTreeController, cellIdentifierForItem item: AnyObject) -> String {
		return (item as! NCTreeNode).cellIdentifier
	}
	
	func treeController(_ treeController: NCTreeController, configureCell cell: UITableViewCell, withItem item: AnyObject) {
		(item as? NCTreeNode)?.configure(cell: cell)
	}*/
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let item = node as? NCFittingModuleRow else {return}
		guard let pilot = fleet?.active else {return}
		//guard let ship = ship else {return}
		guard let typePickerViewController = typePickerViewController else {return}
		
		if item.module.isDummy {
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
