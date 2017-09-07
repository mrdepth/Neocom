//
//  NCZKillboardViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

fileprivate protocol NCZKillboardFilterRow: class {
}

extension NCZKillboardFilterRow {
	
	func configureAccessoryButton(for cell: NCTableViewCell) {
		let button = UIButton(type: .system)
		button.setImage(#imageLiteral(resourceName: "clear"), for: .normal)
		button.sizeToFit()
		button.tintColor = UIColor(white: 0.7, alpha: 0.5)
		cell.accessoryButtonHandler = NCActionHandler(button, for: .touchUpInside) { [weak self] _ in
			guard let strongSelf = self as? TreeNode else {return}
			guard let controller = strongSelf.treeController else {return}
			controller.delegate?.treeController?(controller, accessoryButtonTappedWithNode: strongSelf)
		}
		
		cell.accessoryView = button
	}
}

fileprivate class NCZKillboardContactRow: NCContactRow, NCZKillboardFilterRow {
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCContactTableViewCell else {return}
		
		configureAccessoryButton(for: cell)
	}
}

fileprivate class NCZKillboardShipRow: TreeRow, NCZKillboardFilterRow {

	let ship: NSManagedObject
	init(ship: NSManagedObject, route: Route?) {
		self.ship = ship
		super.init(prototype: Prototype.NCDefaultTableViewCell.compact, route: route)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		if let group = ship as? NCDBInvGroup {
			cell.titleLabel?.text = group.groupName
			cell.iconView?.image = group.category?.categoryID == Int32(NCDBCategoryID.structure.rawValue) ? NCDatabase.sharedDatabase?.eveIcons["40_14"]?.image?.image : #imageLiteral(resourceName: "priceShip")
		}
		else if let type = ship as? NCDBInvType {
			cell.titleLabel?.text = type.typeName
			cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		}
		
		configureAccessoryButton(for: cell)
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCZKillboardShipRow)?.hashValue == hashValue
	}
	
	override var hashValue: Int {
		return ship.hashValue
	}

}

fileprivate class NCZKillboardLocationRow: TreeRow, NCZKillboardFilterRow {
	
	let location: NSManagedObject
	init(location: NSManagedObject, route: Route?) {
		self.location = location
		super.init(prototype: Prototype.NCDefaultTableViewCell.noImage, route: route)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		if let region = location as? NCDBMapRegion {
			cell.titleLabel?.text = region.regionName
			cell.subtitleLabel?.text = nil
		}
		else if let solarSystem = location as? NCDBMapSolarSystem {
			cell.titleLabel?.attributedText = NCLocation(solarSystem).displayName
			cell.subtitleLabel?.text = solarSystem.constellation?.region?.regionName
		}
		
		configureAccessoryButton(for: cell)
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCZKillboardLocationRow)?.hashValue == hashValue
	}
	
	override var hashValue: Int {
		return location.hashValue
	}
	
}

fileprivate class NCZKillboardDateRow: TreeRow, NCZKillboardFilterRow {
	
	enum Bound {
		case lower
		case upper
	}
	
	let bound: Bound
	var date: Date? {
		didSet {
			cellIdentifier = date == nil ? Prototype.NCActionTableViewCell.default.reuseIdentifier : Prototype.NCDefaultTableViewCell.noImage.reuseIdentifier
		}
	}
	init(bound: Bound) {
		self.bound = bound
		super.init(prototype: Prototype.NCActionTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		if let date = date {
			guard let cell = cell as? NCDefaultTableViewCell else {return}
			cell.titleLabel?.text = bound == .lower ? NSLocalizedString("From", comment: "") : NSLocalizedString("To", comment: "")
			cell.subtitleLabel?.text = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
			
			configureAccessoryButton(for: cell)
		}
		else {
			guard let cell = cell as? NCActionTableViewCell else {return}
			cell.titleLabel?.text = bound == .lower ? NSLocalizedString("From Date", comment: "").uppercased() : NSLocalizedString("To Date", comment: "").uppercased()
		}
	}
}

fileprivate class NCZKillboardSwitchRow: NCSwitchRow {
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCSwitchTableViewCell else {return}
		cell.titleLabel.textColor = .caption
	}
}


class NCZKillboardViewController: NCTreeViewController, NCContactsSearchResultViewControllerDelegate {
	
	private var defaultRows: [TreeNode]?
	private var actionsSection: TreeNode?
	private var moreSection: TreeNode?
	private var moreRows: [TreeNode]?
	
	private var killsRow: TreeNode?
	private var lossesRow: TreeNode?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCContactTableViewCell.compact,
		                    Prototype.NCActionTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.noImage,
		                    Prototype.NCDatePickerTableViewCell.default,
		                    Prototype.NCSwitchTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.empty])
		
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		
		var rows: [TreeNode] = [
			NCActionRow(title: NSLocalizedString("Select Pilot", comment: "").uppercased(), route: Router.KillReports.SearchContact(delegate: self)),
			NCActionRow(title: NSLocalizedString("Select Ship", comment: "").uppercased(), route: Router.KillReports.TypePicker { [weak self] (controller, result) in
				self?.select(ship: result as! NSManagedObject)
				controller.dismiss(animated: true, completion: nil)
			}),
			NCActionRow(title: NSLocalizedString("Select Solar System", comment: "").uppercased(), route: Router.Database.LocationPicker(mode: NCLocationPickerViewController.Mode.all) { [weak self] (controller, result) in
				self?.select(location: result as! NSManagedObject)
				controller.dismiss(animated: true, completion: nil)
			}),
			NCZKillboardDateRow(bound: .lower),
			NCZKillboardDateRow(bound: .upper)
		]
		
		defaultRows = rows
		
		let kills = Router.Custom { [weak self] (controller, sender) in
			self?.showReports(.kills, from: sender)
		}
		
		let losses = Router.Custom { [weak self] (controller, sender) in
			self?.showReports(.losses, from: sender)
		}
		

		self.moreRows = [NCZKillboardSwitchRow(title: NSLocalizedString("Solo", comment: "").uppercased(), value: false, handler: { [weak self] _ in
			self?.update()
		}),
		                 NCZKillboardSwitchRow(title: NSLocalizedString("W-Space", comment: "").uppercased(), value: false, handler: { [weak self] _ in
							self?.update()
						})]
		
		moreSection = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, nodeIdentifier: "More",
		                                 children: moreRows)
		
		rows.append(moreSection!)

		killsRow = NCActionRow(title: NSLocalizedString("Search Kills", comment: "").uppercased(), route: kills)
		lossesRow = NCActionRow(title: NSLocalizedString("Search Losses", comment: "").uppercased(), route: losses)
		
		actionsSection = DefaultTreeSection(prototype: Prototype.NCHeaderTableViewCell.empty, nodeIdentifier: "Actions",
		                                    children: /*[NCActionRow(title: NSLocalizedString("Search Kills", comment: "").uppercased(), route: kills),
		                                               NCActionRow(title: NSLocalizedString("Search Losses", comment: "").uppercased(), route: losses)]*/ nil)
		rows.append(actionsSection!)
		
		treeController?.content = RootNode(rows)
		completionHandler()
	}
	
	private func showReports(_ type: ZKillboard.Filter, from: Any?) {
		var filter = self.filter
		filter.append(type)
		
		
		if let contact = (treeController?.content?.children[0] as? NCZKillboardContactRow)?.contact {
			contact.lastUse = Date() as NSDate
			if contact.managedObjectContext?.hasChanges == true {
				try? contact.managedObjectContext?.save()
			}
		}
		
		if let location = (treeController?.content?.children[2] as? NCZKillboardLocationRow)?.location, let context = NCCache.sharedCache?.viewContext {
			if let solarSystem = location as? NCDBMapSolarSystem {
				let location: NCCacheLocationPickerRecent = context.fetch("LocationPickerRecent", where: "locationID == %d", solarSystem.solarSystemID) ?? {
					let location = NCCacheLocationPickerRecent(entity: NSEntityDescription.entity(forEntityName: "LocationPickerRecent", in: context)!, insertInto: context)
					location.locationID = solarSystem.solarSystemID
					location.locationType = NCCacheLocationPickerRecent.LocationType.solarSystem.rawValue
					return location
				}()
				location.date = Date() as NSDate
			}
			else if let region = location as? NCDBMapRegion {
				let location: NCCacheLocationPickerRecent = context.fetch("LocationPickerRecent", where: "locationID == %d", region.regionID) ?? {
					let location = NCCacheLocationPickerRecent(entity: NSEntityDescription.entity(forEntityName: "LocationPickerRecent", in: context)!, insertInto: context)
					location.locationID = region.regionID
					location.locationType = NCCacheLocationPickerRecent.LocationType.region.rawValue
					return location
					}()
				location.date = Date() as NSDate
			}
			
			if context.hasChanges {
				try? context.save()
			}
		}
		
		Router.KillReports.ZKillboardReports(filter: filter).perform(source: self, sender: from)
	}
	
	private func select(ship: NSManagedObject) {
		let row = NCZKillboardShipRow(ship: ship, route: (self.defaultRows?[1] as? TreeNodeRoutable)?.route)
		treeController?.content?.children[1] = row
		update()
	}

	private func select(location: NSManagedObject) {
		let row = NCZKillboardLocationRow(location: location, route: (self.defaultRows?[2] as? TreeNodeRoutable)?.route)
		treeController?.content?.children[2] = row
		update()
	}
	
	private func update() {
		guard let actionsSection = actionsSection else {return}
		let filter = self.filter
		
		let hasRegion = filter.contains {
			guard case .regionID = $0 else {return false}
			return true
		}
		
		let hasLocation = hasRegion || filter.contains {
			guard case .solarSystemID = $0 else {return false}
			return true
		}

		let hasDate = filter.contains {
			switch $0 {
			case .startTime, .endTime:
				return true
			default:
				return false
			}
		}
		
		let wSpace = filter.contains {
			guard case .wSpace = $0 else {return false}
			return true
		}
		
		if hasLocation && moreSection?.children.count == 2 {
			moreSection?.children.removeLast()
		}
		else if !hasLocation && moreSection?.children.count == 1, let row = moreRows?.last {
			moreSection?.children.append(row)
		}
		
		if wSpace && filter.count == 1 {
			actionsSection.children = [lossesRow!]
		}
		else if filter.isEmpty || (hasRegion && hasDate) {
			actionsSection.children = []
		}
		else {
			actionsSection.children = [killsRow!, lossesRow!]
		}
	}
	
	private var filter: [ZKillboard.Filter] {
		var filter = treeController?.content?.children.flatMap { node -> ZKillboard.Filter? in
			switch node {
			case let node as NCZKillboardContactRow:
				guard let contact = node.contact else {break}
				switch contact.recipientType {
				case .character?:
					return .characterID([contact.contactID])
				case .corporation?:
					return .corporationID([contact.contactID])
				case .alliance?:
					return .allianceID([contact.contactID])
				default:
					break
				}
			case let node as NCZKillboardShipRow:
				if let ship = node.ship as? NCDBInvType {
					return .shipTypeID([Int(ship.typeID)])
				}
				else if let group = node.ship as? NCDBInvGroup {
					return .groupID([Int(group.groupID)])
				}
			case let node as NCZKillboardLocationRow:
				if let region = node.location as? NCDBMapRegion {
					return .regionID([Int(region.regionID)])
				}
				else if let solarSystem = node.location as? NCDBMapSolarSystem {
					return .solarSystemID([Int(solarSystem.solarSystemID)])
				}
			case let node as NCZKillboardDateRow:
				guard let date = node.date else {break}
				return node.bound == .lower ? .startTime(date) : .endTime(date.addingTimeInterval(3600 * 24))
			default:
				break
			}
			return nil
		} ?? []
		
		if (moreSection?.children.first as? NCSwitchRow)?.value == true {
			filter.append(.solo)
		}
		if moreSection?.children.count == 2 && (moreSection?.children[1] as? NCSwitchRow)?.value == true {
			filter.append(.wSpace)
		}
		
		return filter
	}

	//MARK: - TreeControllerDelegate
	
	private lazy var range: Range<Date> = {
		let calendar = Calendar(identifier: .gregorian)
		let lower = calendar.date(from: DateComponents(year: 2003, month: 5, day: 6))
		let components = calendar.dateComponents([.year, .month, .day], from: Date())
		let upper = calendar.date(from: components)
		return lower!..<upper!

	}()
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		if let node = node as? NCZKillboardDateRow {
			if node.children.isEmpty {
				let date = node.date ?? (node.bound == .lower ? range.lowerBound : range.upperBound)
				let row = NCDatePickerRow(value: date, range: range) { [weak self, weak node] date in
					guard let strongSelf = self else {return}
					guard let node = node else {return}
					node.date = date
					strongSelf.treeController?.reloadCells(for: [node], with: .none)
					
				}
				node.date = date
				treeController.reloadCells(for: [node], with: .fade)
				node.children = [row]
				update()
			}
			else {
				node.children = []
			}
		}
	}
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		if let node = node as? NCZKillboardDateRow {
			node.date = nil
			treeController.reloadCells(for: [node], with: .fade)
			if !node.children.isEmpty {
				node.children = []
			}
		}
		else {
			guard let i = treeController.content?.children.index(of: node) else {return}
			guard let row = defaultRows?[i] else {return}
			treeController.content?.children[i] = row
		}
		update()
	}
	
	//MARK: - NCContactsSearchResultViewControllerDelegate
	
	func contactsSearchResultsViewController(_ controller: NCContactsSearchResultViewController, didSelect contact: NCContact) {
		controller.dismiss(animated: true, completion: nil)
		let row = NCZKillboardContactRow(contact: contact, dataManager: dataManager)
		row.route = Router.KillReports.SearchContact(delegate: self)
		treeController?.content?.children[0] = row
		update()
	}
	
}
