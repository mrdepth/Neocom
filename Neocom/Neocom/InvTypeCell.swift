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
			switch cell {
			case let cell as InvTypeModuleCell:
				cell.titleLabel?.text = type?.typeName
				cell.iconView?.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
				cell.cpuLabel.text = UnitFormatter.localizedString(from: requirements?.cpu ?? 0, unit: .teraflops, style: .long)
				cell.powerGridLabel.text = UnitFormatter.localizedString(from: requirements?.powerGrid ?? 0, unit: .megaWatts, style: .long)
			case let cell as InvTypeShipCell:
				cell.titleLabel?.text = type?.typeName
				cell.iconView?.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
				cell.hiSlotsLabel.text = "\(shipResources?.hiSlots ?? 0)"
				cell.medSlotsLabel.text = "\(shipResources?.medSlots ?? 0)"
				cell.lowSlotsLabel.text = "\(shipResources?.lowSlots ?? 0)"
				cell.rigSlotsLabel.text = "\(shipResources?.rigSlots ?? 0)"
				cell.turretsLabel.text = "\(shipResources?.turrets ?? 0)"
				cell.launchersLabel.text = "\(shipResources?.launchers ?? 0)"
			case let cell as InvTypeChargeCell:
				cell.titleLabel?.text = type?.typeName
				cell.iconView?.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
				
				let em = damage?.emAmount ?? 0
				let kinetic = damage?.kineticAmount ?? 0
				let thermal = damage?.thermalAmount ?? 0
				let explosive = damage?.explosiveAmount ?? 0
				var total = em + kinetic + thermal + explosive
				if total == 0 {
					total = 1
				}
				
				cell.emLabel.progress = em / total
				cell.emLabel.text = UnitFormatter.localizedString(from: em, unit: .none, style: .short)
				
				cell.kineticLabel.progress = kinetic / total
				cell.kineticLabel.text = UnitFormatter.localizedString(from: kinetic, unit: .none, style: .short)
				
				cell.thermalLabel.progress = thermal / total
				cell.thermalLabel.text = UnitFormatter.localizedString(from: thermal, unit: .none, style: .short)
				
				cell.explosiveLabel.progress = explosive / total
				cell.explosiveLabel.text = UnitFormatter.localizedString(from: explosive, unit: .none, style: .short)
			case let cell as InvTypeCell:
				cell.titleLabel?.text = type?.typeName
				cell.iconView?.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
				cell.subtitleLabel?.isHidden = true
				cell.accessoryType = .disclosureIndicator
			default:
				break
			}
		}
	}
	
}
