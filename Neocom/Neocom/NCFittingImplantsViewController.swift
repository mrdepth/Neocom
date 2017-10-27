//
//  NCFittingImplantsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData

class NCImplantRow: TreeRow {
	lazy var type: NCDBInvType? = {
		guard let implant = self.implant else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[implant.typeID]
	}()

	
	let implant: NCFittingImplant?
	let slot: Int?
	init(implant: NCFittingImplant) {
		self.implant = implant
		self.slot = nil
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact, accessoryButtonRoute: Router.Database.TypeInfo(implant.typeID))
	}
	
	init(dummySlot: Int) {
		self.implant = nil
		self.slot = dummySlot
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact)
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

class NCBoosterRow: TreeRow {
	lazy var type: NCDBInvType? = {
		guard let booster = self.booster else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[booster.typeID]
	}()

	let booster: NCFittingBooster?
	let slot: Int?
	init(booster: NCFittingBooster) {
		self.booster = booster
		self.slot = nil
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact, accessoryButtonRoute: Router.Database.TypeInfo(booster.typeID))
	}
	
	init(dummySlot: Int) {
		self.booster = nil
		self.slot = dummySlot
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact)
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
			cell.iconView?.image = #imageLiteral(resourceName: "booster")
			cell.accessoryType = .none
		}
	}
	
	override var hashValue: Int {
		return booster?.hashValue ?? slot ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCBoosterRow)?.hashValue == hashValue
	}
	
}


class NCFittingImplantsViewController: NCTreeViewController, NCFittingEditorPage {
	
	private var observer: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCActionTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default
			])

	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if observer == nil {
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingEngineDidUpdate, object: engine, queue: nil) { [weak self] (note) in
				self?.reload()
			}
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		defer {
			completionHandler()
		}
		guard editorViewController != nil else {return}
		treeController?.content = TreeNode()
		reload()
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		
		if let item = (node as? NCImplantRow)?.implant ?? (node as? NCBoosterRow)?.booster {
			let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			controller.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { [weak self] _ in
				guard let pilot = self?.fleet?.active else {return}
				self?.engine?.perform {
					if let implant = item as? NCFittingImplant {
						pilot.removeImplant(implant)
					}
					else if let booster = item as? NCFittingBooster {
						pilot.removeBooster(booster)
					}
				}
			})
			
			controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
			
			present(controller, animated: true, completion: nil)
			let sender = treeController.cell(for: node)
			controller.popoverPresentationController?.sourceView = sender
			controller.popoverPresentationController?.sourceRect = sender?.bounds ?? .zero

		}
		else if let row = node as? NCImplantRow {
			if let slot = row.slot {
				guard let pilot = fleet?.active else {return}
				guard let typePickerViewController = typePickerViewController else {return}
				let category = NCDBDgmppItemCategory.category(categoryID: .implant, subcategory: slot)
				
				typePickerViewController.category = category
				typePickerViewController.completionHandler = { [weak typePickerViewController, weak self] (_, type) in
					let typeID = Int(type.typeID)
					pilot.engine?.perform {
						pilot.addImplant(typeID: typeID)
					}
					if self?.editorViewController?.traitCollection.horizontalSizeClass == .compact || self?.traitCollection.userInterfaceIdiom == .phone {
						typePickerViewController?.dismiss(animated: true)
					}
				}
				Route(kind: .popover, viewController: typePickerViewController).perform(source: self, sender: treeController.cell(for: node))
			}
		}
		else if let row = node as? NCBoosterRow {
			if let slot = row.slot {
				guard let pilot = fleet?.active else {return}
				guard let typePickerViewController = typePickerViewController else {return}
				let category = NCDBDgmppItemCategory.category(categoryID: .booster, subcategory: slot)
				
				typePickerViewController.category = category
				typePickerViewController.completionHandler = { [weak typePickerViewController, weak self] (_, type) in
					let typeID = Int(type.typeID)
					pilot.engine?.perform {
						pilot.addBooster(typeID: typeID)
					}
					if self?.editorViewController?.traitCollection.horizontalSizeClass == .compact || self?.traitCollection.userInterfaceIdiom == .phone {
						typePickerViewController?.dismiss(animated: true)
					}
				}
				Route(kind: .popover, viewController: typePickerViewController).perform(source: self, sender: treeController.cell(for: node))
			}
		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let item = (node as? NCImplantRow)?.implant ?? (node as? NCBoosterRow)?.booster else {return nil}
		guard let engine = engine else {return nil}
		guard let pilot = self.fleet?.active else {return nil}
		
		let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { (_, _) in
			engine.perform {
				if let implant = item as? NCFittingImplant {
					pilot.removeImplant(implant)
				}
				else if let booster = item as? NCFittingBooster {
					pilot.removeBooster(booster)
				}
			}
		}
		
		return [deleteAction]
	}
	
	//MARK: - Private
	
	private func reload() {
		
		
		let boosterCategories: [NCDBDgmppItemCategory]? = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemCategory", where: "category == %d", NCDBDgmppItemCategoryID.booster.rawValue)
		let boosterSlots = boosterCategories?.map {Int($0.subcategory)}.sorted() ?? [1,2,3,4]

		engine?.perform {
			guard let pilot = self.fleet?.active else {return}
			var sections = [TreeNode]()
			
			var implants = (0...9).map({NCImplantRow(dummySlot: $0 + 1)})
			
			for implant in pilot.implants.all {
				guard (1...10).contains(implant.slot) else {continue}
				implants[implant.slot - 1] = NCImplantRow(implant: implant)
			}
			
			var boosters = boosterSlots.map({NCBoosterRow(dummySlot: $0)})
			
			for booster in pilot.boosters.all {
//				guard boosterSlots.contains(booster.slot) else {continue}
				guard let i = boosters.index(where: {$0.slot == booster.slot}) else {continue}
				boosters[i] = NCBoosterRow(booster: booster)
//				boosters[booster.slot - 1] = NCBoosterRow(booster: booster)
			}
			
			var actions = [TreeNode]()
			actions.append(NCActionRow(title: NSLocalizedString("Load Implant Set", comment: "").uppercased(), route: Router.Fitting.ImplantSet(load: { [weak self] (controller, implantSet) in
				controller.dismiss(animated: true, completion: nil)
				guard let pilot = self?.fleet?.active else {return}
				
				let implantIDs = implantSet.data?.implantIDs
				let boosterIDs = implantSet.data?.boosterIDs
				
				pilot.engine?.perform {
					implantIDs?.forEach {pilot.addImplant(typeID: $0, forced: true)}
					boosterIDs?.forEach {pilot.addBooster(typeID: $0, forced: true)}
				}
			})))
			
			if !pilot.implants.all.isEmpty || !pilot.boosters.all.isEmpty {
				actions.append(NCActionRow(title: NSLocalizedString("Save Implant Set", comment: "").uppercased(), route: Router.Fitting.ImplantSet(save: pilot)))
			}
			sections.append(RootNode(actions))

			sections.append(DefaultTreeSection(nodeIdentifier: "Implants", title: NSLocalizedString("Implants", comment: "").uppercased(), children: implants))
			sections.append(DefaultTreeSection(nodeIdentifier: "Boosters", title: NSLocalizedString("Boosters", comment: "").uppercased(), children: boosters))
			
			DispatchQueue.main.async {
				self.treeController?.content?.children = sections
			}
		}
	}
}
