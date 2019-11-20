//
//  InvTypeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import TreeController
import Expressible

typealias InvTypeCell = TreeDefaultCell

class InvTypeModuleCell: RowCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var powerGridLabel: UILabel!
	@IBOutlet weak var cpuLabel: UILabel!
}

class InvTypeShipCell: RowCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var hiSlotsLabel: UILabel!
	@IBOutlet weak var medSlotsLabel: UILabel!
	@IBOutlet weak var lowSlotsLabel: UILabel!
	@IBOutlet weak var rigSlotsLabel: UILabel!
	@IBOutlet weak var turretsLabel: UILabel!
	@IBOutlet weak var launchersLabel: UILabel!
}

class InvTypeChargeCell: RowCell {
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var emLabel: DamageTypeLabel!
	@IBOutlet weak var thermalLabel: DamageTypeLabel!
	@IBOutlet weak var kineticLabel: DamageTypeLabel!
	@IBOutlet weak var explosiveLabel: DamageTypeLabel!
}

extension Prototype {
	enum InvTypeCell {
		static let `default` = Prototype.TreeDefaultCell.default
		static let module = Prototype(nib: UINib(nibName: "InvTypeModuleCell", bundle: nil), reuseIdentifier: "InvTypeModuleCell")
		static let ship = Prototype(nib: UINib(nibName: "InvTypeShipCell", bundle: nil), reuseIdentifier: "InvTypeShipCell")
		static let charge = Prototype(nib: UINib(nibName: "InvTypeChargeCell", bundle: nil), reuseIdentifier: "InvTypeChargeCell")
	}
}


extension Tree.Item {
	class InvType: Tree.Item.FetchedResultsRow<NSDictionary>, Routable {
		
		lazy var route: Routing? = (self.result["objectID"] as? NSManagedObjectID).map{Router.SDE.invTypeInfo(.objectID($0))}
		
		var secondaryRoute: Routing?
		
		lazy var type: SDEInvType? = {
			guard let objectID = result["objectID"] as? NSManagedObjectID else {return nil}
			return (try? Services.sde.viewContext.existingObject(with: objectID)) ?? nil
		}()
		
		lazy var requirements: SDEDgmppItemRequirements? = {
			guard let objectID = result["requirements"] as? NSManagedObjectID else {return nil}
			return (try? Services.sde.viewContext.existingObject(with: objectID)) ?? nil
		}()
		
		lazy var shipResources: SDEDgmppItemShipResources? = {
			guard let objectID = result["shipResources"] as? NSManagedObjectID else {return nil}
			return (try? Services.sde.viewContext.existingObject(with: objectID)) ?? nil
		}()
		
		lazy var damage: SDEDgmppItemDamage? = {
			guard let objectID = result["damage"] as? NSManagedObjectID else {return nil}
			return (try? Services.sde.viewContext.existingObject(with: objectID)) ?? nil
		}()
		
		override var prototype: Prototype? {
			if result["shipResources"] != nil {
				return Prototype.InvTypeCell.ship
			}
			else if result["damage"] != nil {
				return Prototype.InvTypeCell.charge
			}
			else if result["requirements"] != nil {
				return Prototype.InvTypeCell.module
			}
			else {
				return Prototype.InvTypeCell.default
			}
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			switch cell {
			case let cell as InvTypeModuleCell:
				requirements?.configure(cell: cell, treeController: treeController)
			case let cell as InvTypeShipCell:
				shipResources?.configure(cell: cell, treeController: treeController)
			case let cell as InvTypeChargeCell:
				damage?.configure(cell: cell, treeController: treeController)
			case let cell as InvTypeCell:
				type?.configure(cell: cell, treeController: treeController)
				cell.accessoryType = .disclosureIndicator
			default:
				break
			}
		}
	}
}

extension SDEInvType: CellConfigurable {
	var prototype: Prototype? {
		return Prototype.TreeDefaultCell.default
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? TreeDefaultCell else {return}
		cell.titleLabel?.text = typeName
		cell.subtitleLabel?.isHidden = true
		cell.iconView?.image = icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
		cell.iconView?.isHidden = false
	}
}

extension SDEDgmppItemRequirements: CellConfigurable {
	
	var prototype: Prototype? {
		return Prototype.InvTypeCell.module
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? InvTypeModuleCell else {return}
		let type = item?.type
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
		cell.cpuLabel.text = UnitFormatter.localizedString(from: cpu, unit: .teraflops, style: .long)
		cell.powerGridLabel.text = UnitFormatter.localizedString(from: powerGrid, unit: .megaWatts, style: .long)
	}
}

extension SDEDgmppItemShipResources: CellConfigurable {
	var prototype: Prototype? {
		return Prototype.InvTypeCell.ship
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? InvTypeShipCell else {return}
		let type = item?.type
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
		cell.hiSlotsLabel.text = "\(hiSlots)"
		cell.medSlotsLabel.text = "\(medSlots)"
		cell.lowSlotsLabel.text = "\(lowSlots)"
		cell.rigSlotsLabel.text = "\(rigSlots)"
		cell.turretsLabel.text = "\(turrets)"
		cell.launchersLabel.text = "\(launchers)"

	}
}

extension SDEDgmppItemDamage: CellConfigurable {
	var prototype: Prototype? {
		return Prototype.InvTypeCell.charge
	}
	
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? InvTypeChargeCell else {return}
		let type = item?.type
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
		
		var total = emAmount + kineticAmount + thermalAmount + explosiveAmount
		if total == 0 {
			total = 1
		}
		
		[(cell.emLabel, emAmount),
		 (cell.kineticLabel, kineticAmount),
		 (cell.thermalLabel, thermalAmount),
		 (cell.explosiveLabel, explosiveAmount)].forEach { (label, amount) in
			label?.progress = amount / total
			label?.text = UnitFormatter.localizedString(from: amount, unit: .none, style: .short)
		}
	}
}

extension Tree.Item.InvType {
	class var propertiesToFetch: [PropertyDescriptionConvertible] {
		return [Self.as(NSManagedObjectID.self, name: "objectID"),
				(\SDEInvType.dgmppItem?.requirements).as(NSManagedObjectID.self, name: "requirements"),
				(\SDEInvType.dgmppItem?.shipResources).as(NSManagedObjectID.self, name: "shipResources"),
				(\SDEInvType.dgmppItem?.damage).as(NSManagedObjectID.self, name: "damage")]
	}
}
