//
//  InvTypeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

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
	class InvType: Tree.Item.FetchedResultsRow<NSDictionary> {
		
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
			if shipResources != nil {
				return Prototype.InvTypeCell.ship
			}
			else if damage != nil {
				return Prototype.InvTypeCell.charge
			}
			else if requirements != nil {
				return Prototype.InvTypeCell.module
			}
			else {
				return Prototype.InvTypeCell.default
			}
		}
		
		override func configure(cell: UITableViewCell) {
		}
	}
	
}
