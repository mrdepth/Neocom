//
//  NCKillmailAttackerTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCKillmailAttackerTableViewCell: NCDefaultTableViewCell {
	@IBOutlet weak var shipImageView: UIImageView?
	@IBOutlet weak var shipLabel: UILabel?
	@IBOutlet weak var weaponLabel: UILabel?
}

extension Prototype {
	enum NCKillmailAttackerTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCKillmailAttackerTableViewCell", bundle: nil), reuseIdentifier: "NCKillmailAttackerTableViewCell")
		static let npc = Prototype(nib: UINib(nibName: "NCKillmailAttackerNPCTableViewCell", bundle: nil), reuseIdentifier: "NCKillmailAttackerNPCTableViewCell")
	}
}

class NCKillmailAttackerRow: TreeRow {
	let attacker: NCAttacker
	let characterID: NSManagedObjectID?
	let corporationID: NSManagedObjectID?
	let allianceID: NSManagedObjectID?
	let dataManager: NCDataManager
	
	lazy var character: NCContact? = {
		guard let contactID = self.characterID else {return nil}
		return (try? NCCache.sharedCache?.viewContext.existingObject(with: contactID)) as? NCContact
	}()
	
	lazy var corporation: NCContact? = {
		guard let contactID = self.corporationID else {return nil}
		return (try? NCCache.sharedCache?.viewContext.existingObject(with: contactID)) as? NCContact
	}()
	
	lazy var alliance: NCContact? = {
		guard let contactID = self.allianceID else {return nil}
		return (try? NCCache.sharedCache?.viewContext.existingObject(with: contactID)) as? NCContact
	}()
	
	init(attacker: NCAttacker, character: NSManagedObjectID?, corporation: NSManagedObjectID?, alliance: NSManagedObjectID?, dataManager: NCDataManager) {
		self.attacker = attacker
		self.characterID = character
		self.corporationID = corporation
		self.allianceID = alliance
		self.dataManager = dataManager
		let contact = character ?? corporation ?? alliance
		super.init(prototype: contact == nil ? Prototype.NCKillmailAttackerTableViewCell.npc : Prototype.NCKillmailAttackerTableViewCell.default)
		
		if let contact = contact {
			route = Router.KillReports.ContactReports(contact: contact)
		}
	}
	
	lazy var faction: NCDBChrFaction? = {
		guard let factionID = self.attacker.factionID else {return nil}
		return NCDatabase.sharedDatabase?.chrFactions[factionID]
	}()
	
	lazy var shipType: NCDBInvType? = {
		guard let shipTypeID = self.attacker.shipTypeID else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[shipTypeID]
	}()
	
	lazy var weaponType: NCDBInvType? = {
		guard let weaponTypeID = self.attacker.weaponTypeID else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[weaponTypeID]
	}()
	
	lazy var subtitle: String = {
		var s = ""
		switch (self.corporation?.name, self.alliance?.name) {
		case let (a?, b?):
			s = "\(a) / \(b)\n"
		case let (a?, nil):
			s = a + "\n"
		case let (nil, b?):
			s = b + "\n"
		default:
			break
		}
		
		if let ship = self.shipType?.typeName {
			if let weapon = self.weaponType?.typeName {
				s += String(format: NSLocalizedString("%@ with %@", comment: ""), ship, weapon) + "\n"
			}
			else {
				s += ship + "\n"
			}
		}
		s += String(format: NSLocalizedString("%@ damage done", comment: ""), NCUnitFormatter.localizedString(from: self.attacker.damageDone, unit: .none, style: .full))
		//		if self.attacker.finalBlow {
		//			s += " (\(NSLocalizedString("final blow", comment: "")))"
		//		}
		return s
	}()
	
	var image: UIImage?
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCKillmailAttackerTableViewCell else {return}
		
		cell.iconView?.image = image
		cell.object = attacker
		
		if let contact = character ?? corporation ?? alliance {
			cell.titleLabel?.text = contact.name
			cell.shipLabel?.text = shipType?.typeName
			cell.shipImageView?.image = shipType?.icon?.image?.image
			
			switch (self.corporation?.name, self.alliance?.name) {
			case let (a?, b?):
				cell.subtitleLabel?.text = "\(a) / \(b)"
			case let (a?, nil):
				cell.subtitleLabel?.text = a
			case let (nil, b?):
				cell.subtitleLabel?.text = b
			default:
				break
			}
			
			if let weapon = weaponType?.typeName {
				cell.weaponLabel?.text = String(format: NSLocalizedString("%@ damage done with %@", comment: ""), NCUnitFormatter.localizedString(from: self.attacker.damageDone, unit: .none, style: .full), weapon)
			}
			else {
				cell.weaponLabel?.text = String(format: NSLocalizedString("%@ damage done", comment: ""), NCUnitFormatter.localizedString(from: self.attacker.damageDone, unit: .none, style: .full))
			}
		}
		else if let faction = self.faction {
			cell.titleLabel?.text = faction.factionName
			cell.shipLabel?.text = shipType?.typeName
			cell.shipImageView?.image = shipType?.icon?.image?.image
			cell.weaponLabel?.text = String(format: NSLocalizedString("%@ damage done", comment: ""), NCUnitFormatter.localizedString(from: self.attacker.damageDone, unit: .none, style: .full))
		}
		else {
			cell.titleLabel?.text = NSLocalizedString("Unknown", comment: "")
			cell.shipLabel?.text = shipType?.typeName
			cell.shipImageView?.image = shipType?.icon?.image?.image
			cell.weaponLabel?.text = String(format: NSLocalizedString("%@ damage done", comment: ""), NCUnitFormatter.localizedString(from: self.attacker.damageDone, unit: .none, style: .full))
		}
		
		cell.accessoryType = route != nil ? .disclosureIndicator : .none
		
		if attacker.finalBlow {
			cell.titleLabel?.attributedText = (cell.titleLabel?.text ?? "") + " [\(NSLocalizedString("final blow", comment: ""))]" * [NSAttributedStringKey.foregroundColor: UIColor.caption]
		}
		
		if image == nil, let size = cell.iconView?.bounds.size {
			image = UIImage()
			if let contact = self.character {
				dataManager.image(characterID: contact.contactID, dimension: Int(size.width)).then(on: .main) { result in
					self.image = result.value
					if (cell.object as? NCAttacker)?.characterID == self.attacker.characterID {
						cell.iconView?.image = self.image
					}
				}
			}
			else if let contact = self.corporation {
				dataManager.image(corporationID: contact.contactID, dimension: Int(size.width)).then(on: .main) { result in
					self.image = result.value
					if (cell.object as? NCAttacker)?.corporationID == self.attacker.corporationID {
						cell.iconView?.image = self.image
					}
				}
			}
			else if let contact = self.alliance {
				dataManager.image(allianceID: contact.contactID, dimension: Int(size.width)).then(on: .main) { result in
					self.image = result.value
					if (cell.object as? NCAttacker)?.allianceID == self.attacker.allianceID {
						cell.iconView?.image = self.image
					}
				}
			}
			else if let contact = self.faction {
				dataManager.image(allianceID: Int64(contact.factionID), dimension: Int(size.width)).then(on: .main) { result in
					self.image = result.value
					if (cell.object as? NCAttacker)?.factionID == self.attacker.factionID {
						cell.iconView?.image = self.image
					}
				}
			}
		}
	}
}
