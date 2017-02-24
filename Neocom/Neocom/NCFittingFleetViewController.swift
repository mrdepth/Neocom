//
//  NCFittingFleetViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFleetMemberRow: TreeRow {
	lazy var type: NCDBInvType? = {
		guard let implant = self.implant else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[implant.typeID]
	}()
	
	
	let implant: NCFittingImplant?
	let slot: Int?
	init(implant: NCFittingImplant) {
		self.implant = implant
		self.slot = nil
		super.init(cellIdentifier: "NCDefaultTableViewCell", accessoryButtonRoute: Router.Database.TypeInfo(implant.typeID))
	}
	
	init(dummySlot: Int) {
		self.implant = nil
		self.slot = dummySlot
		super.init(cellIdentifier: "NCDefaultTableViewCell")
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		if let type = type {
			cell.titleLabel?.text = type.typeName
			cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.accessoryType = .detailButton
		}
		else {
			cell.titleLabel?.text = NSLocalizedString("Slot", comment: "") + " \(slot ?? 0)"
			cell.iconView?.image = #imageLiteral(resourceName: "implant")
			cell.accessoryType = .none
		}
	}
	
	override var hashValue: Int {
		return implant?.hashValue ?? slot ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCImplantRow)?.hashValue == hashValue
	}
	
}


class NCFittingFleetViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet weak var treeController: TreeController!
	
	var engine: NCFittingEngine? {
		return (parent as? NCFittingEditorViewController)?.engine
	}
	
	var fleet: NCFittingFleet? {
		return (parent as? NCFittingEditorViewController)?.fleet
	}
	
	private var observer: NSObjectProtocol?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if self.treeController.rootNode == nil {
			self.treeController.rootNode = TreeNode()
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
		if let route = (node as? TreeRow)?.route {
			route.perform(source: self, view: treeController.cell(for: node))
		}

		
		/*if let item = node as? NCImplantRow {
			if let slot = item.slot {
				guard let pilot = fleet?.active else {return}
				guard let typePickerViewController = typePickerViewController else {return}
				let category = NCDBDgmppItemCategory.category(categoryID: .implant, subcategory: slot)
				
				typePickerViewController.category = category
				typePickerViewController.completionHandler = { [weak typePickerViewController] (_, type) in
					let typeID = Int(type.typeID)
					self.engine?.perform {
						pilot.addImplant(typeID: typeID)
					}
					typePickerViewController?.dismiss(animated: true)
				}
				present(typePickerViewController, animated: true)
			}
		}
		else if let item = node as? NCBoosterRow {
			if let slot = item.slot {
				guard let pilot = fleet?.active else {return}
				guard let typePickerViewController = typePickerViewController else {return}
				let category = NCDBDgmppItemCategory.category(categoryID: .booster, subcategory: slot)
				
				typePickerViewController.category = category
				typePickerViewController.completionHandler = { [weak typePickerViewController] (_, type) in
					let typeID = Int(type.typeID)
					self.engine?.perform {
						pilot.addBooster(typeID: typeID)
					}
					typePickerViewController?.dismiss(animated: true)
				}
				present(typePickerViewController, animated: true)
			}
		}*/
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let route = (node as? TreeRow)?.accessoryButtonRoute else {return}
		
		route.perform(source: self, view: treeController.cell(for: node))
	}
	
	//MARK: - Private
	
	private func reload() {
		guard let fleet = self.fleet else {return}
		if fleet.pilots.count == 1 {
			var route: Route? = nil
			
			route = Router.Fitting.FleetMemberPicker(fleet: fleet, completionHandler: { [weak route] controller in
				route?.unwind()
			})
			
			let row = NCActionRow(cellIdentifier: "NCDefaultTableViewCell", title: NSLocalizedString("Create Fleet", comment: ""), route: route)
			self.treeController.rootNode?.children = [row]
		}
		else {
			
		}
		return
		/*engine?.perform {
			guard let pilot = self.fleet?.active else {return}
			var sections = [TreeNode]()
			
			var implants = (0...9).map({NCImplantRow(dummySlot: $0 + 1)})
			
			for implant in pilot.implants.all {
				guard (1...10).contains(implant.slot) else {continue}
				implants[implant.slot - 1] = NCImplantRow(implant: implant)
			}
			
			var boosters = (0...3).map({NCBoosterRow(dummySlot: $0 + 1)})
			
			for booster in pilot.boosters.all {
				guard (1...4).contains(booster.slot) else {continue}
				boosters[booster.slot - 1] = NCBoosterRow(booster: booster)
			}
			
			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Implants", title: NSLocalizedString("Implants", comment: "").uppercased(), children: implants))
			sections.append(DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Boosters", title: NSLocalizedString("Boosters", comment: "").uppercased(), children: boosters))
			
			DispatchQueue.main.async {
				self.treeController.rootNode?.children = sections
			}
		}*/
	}
}
