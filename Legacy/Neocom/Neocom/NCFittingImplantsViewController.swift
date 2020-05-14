//
//  NCFittingImplantsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData
import Dgmpp
import EVEAPI
import Futures

class NCImplantRow: TreeRow {
	lazy var type: NCDBInvType? = {
		return self.implant?.type
	}()

	
	let implant: DGMImplant?
	let slot: Int?
	init(implant: DGMImplant) {
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
	
	override var hash: Int {
		return implant?.hashValue ?? slot ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCImplantRow)?.hashValue == hashValue
	}
	
}

class NCBoosterRow: TreeRow {
	lazy var type: NCDBInvType? = {
		return self.booster?.type
	}()

	let booster: DGMBooster?
	let slot: Int?
	
	init(booster: DGMBooster) {
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
	
	override var hash: Int {
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
	
	private var needsReload = true
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if observer == nil {
			observer = NotificationCenter.default.addNotificationObserver(forName: .NCFittingFleetDidUpdate, object: fleet, queue: nil) { [weak self] (note) in
				guard self?.view.window != nil else {
					self?.needsReload = true
					return
				}
				self?.updateContent()
			}
		}
		
		if needsReload {
			updateContent()
		}
	}
	
	override func content() -> Future<TreeNode?> {
		guard editorViewController != nil else {return .init(nil)}
		guard let pilot = self.fleet?.active else {return .init(nil)}

		let implantSlots = stride(from: 1, to: 11, by: 1)
		
		let boosterCategories: [NCDBDgmppItemCategory]? = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemCategory", where: "category == %d", NCDBDgmppItemCategoryID.booster.rawValue)
		let boosterSlots = boosterCategories?.map {Int($0.subcategory)}.sorted() ?? [1,2,3,4]
		
		var sections = [TreeNode]()
		
		var implants = implantSlots.map({NCImplantRow(dummySlot: $0)})
		
		for implant in pilot.implants {
			guard let i = implants.index(where: {$0.slot == implant.slot}) else {continue}
			implants[i] = NCImplantRow(implant: implant)
		}
		
		var boosters = boosterSlots.map({NCBoosterRow(dummySlot: $0)})
		
		for booster in pilot.boosters {
			guard let i = boosters.index(where: {$0.slot == booster.slot}) else {continue}
			boosters[i] = NCBoosterRow(booster: booster)
		}
		
		var actions = [TreeNode]()
		actions.append(NCActionRow(title: NSLocalizedString("Load Implant Set", comment: "").uppercased(), route: Router.Fitting.ImplantSet(load: { [weak self] (controller, implantSet) in
			controller.dismiss(animated: true, completion: nil)
			guard let pilot = self?.fleet?.active else {return}
			
			let implantIDs = implantSet.data?.implantIDs
			let boosterIDs = implantSet.data?.boosterIDs
			
			implantIDs?.forEach {try? pilot.add(DGMImplant(typeID: $0), replace: true)}
			boosterIDs?.forEach {try? pilot.add(DGMBooster(typeID: $0), replace: true)}
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
		})))
		
		if !pilot.implants.isEmpty || !pilot.boosters.isEmpty {
			actions.append(NCActionRow(title: NSLocalizedString("Save Implant Set", comment: "").uppercased(), route: Router.Fitting.ImplantSet(save: pilot)))
		}
		sections.append(RootNode(actions))
		
		sections.append(DefaultTreeSection(nodeIdentifier: "Implants", title: NSLocalizedString("Implants", comment: "").uppercased(), children: implants))
		sections.append(DefaultTreeSection(nodeIdentifier: "Boosters", title: NSLocalizedString("Boosters", comment: "").uppercased(), children: boosters))
		
		needsReload = false
		return .init(RootNode(sections))
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		
		if let item = (node as? NCImplantRow)?.implant ?? (node as? NCBoosterRow)?.booster {
			let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			controller.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { [weak self] _ in
				guard let pilot = self?.fleet?.active else {return}
				if let implant = item as? DGMImplant {
					pilot.remove(implant)
				}
				else if let booster = item as? DGMBooster {
					pilot.remove(booster)
				}
				NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
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
					do {
						try pilot.add(DGMImplant(typeID: typeID))
						NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
					}
					catch {
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
					do {
						try pilot.add(DGMBooster(typeID: typeID))
						NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
					}
					catch {
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
		guard let pilot = self.fleet?.active else {return nil}
		
		let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { [weak self] (_, _) in
			if let implant = item as? DGMImplant {
				pilot.remove(implant)
			}
			else if let booster = item as? DGMBooster {
				pilot.remove(booster)
			}
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
		}
		
		return [deleteAction]
	}
	
	//MARK: - Private
	
}
