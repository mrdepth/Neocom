//
//  NCKillmailTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCKillmailTableViewCell: NCTableViewCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var solarSystemLabel: UILabel!
	
}

extension Prototype {
	enum NCKillmailTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCKillmailTableViewCell", bundle: nil), reuseIdentifier: "NCKillmailTableViewCell")
	}
}

class NCKillmailRow: TreeRow {
	
//	let killmail: ESI.Killmails.Killmail?
//	let zKillmail: ZKillboard.Killmail?
	let killmail: NCKillmail
	let dataManager: NCDataManager
	let characterID: Int64?
	
	lazy var type: NCDBInvType? = {
		let shipTypeID = self.killmail.getVictim().shipTypeID
//		guard let shipTypeID = self.killmail?.victim.shipTypeID ?? self.zKillmail?.victim.shipTypeID else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[shipTypeID]
	}()
	
	/*init(killmail: ESI.Killmails.Killmail, characterID: Int64, dataManager: NCDataManager) {
		self.killmail = killmail
		self.zKillmail = nil
		self.characterID = characterID
		self.dataManager = dataManager
		super.init(prototype: Prototype.NCKillmailTableViewCell.default, route: Router.KillReports.Info(killmail: killmail))
	}

	init(killmail: ZKillboard.Killmail, dataManager: NCDataManager) {
		self.killmail = nil
		self.zKillmail = killmail
		self.characterID = nil
		self.dataManager = dataManager
		super.init(prototype: Prototype.NCKillmailTableViewCell.default, route: Router.KillReports.Info(killmail: killmail))
	}*/
	
	lazy var location: NSAttributedString? = {
		guard let solarSystem = NCDatabase.sharedDatabase?.mapSolarSystems[self.killmail.solarSystemID] else {return nil}
		let location = NCLocation(solarSystem).displayName
		let count = self.killmail.getAttackers().count
		return location + " (\(String(format: NSLocalizedString("%@ involved", comment: ""), NCUnitFormatter.localizedString(from: count, unit: .none, style: .full))))"
	}()
	
	init(killmail: NCKillmail, characterID: Int64?, dataManager: NCDataManager) {
		self.killmail = killmail
		self.characterID = characterID
		self.dataManager = dataManager
		super.init(prototype: Prototype.NCKillmailTableViewCell.default, route: Router.KillReports.Info(killmail: killmail))
	}

	var contactName: String?
	lazy var date: String = {
		let date = self.killmail.killmailTime
		return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
	}()
	
	override func configure(cell: UITableViewCell) {
		
		guard let cell = cell as? NCKillmailTableViewCell else {return}
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.titleLabel?.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		cell.object = killmail
		cell.dateLabel.text = date
		cell.solarSystemLabel.attributedText = location
		
		if contactName == nil {
			cell.subtitleLabel?.text = " "
			
			let contactID: Int?
			
			if let characterID = characterID {
				let id = killmail.getVictim().characterID != Int(characterID) ? killmail.getVictim().characterID
					: {
						guard let attacker = killmail.getAttackers().first (where: {$0.finalBlow}) ?? killmail.getAttackers().first else {return nil}
						return attacker.characterID ?? attacker.corporationID ?? attacker.allianceID ?? attacker.factionID
						
					}()
				contactID = id == 0 ? nil : id
			}
			else {
				let id = killmail.getVictim().characterID
				contactID = id == 0 ? nil : id
			}
			
			if let contactID = contactID {
				if let faction = NCDatabase.sharedDatabase?.chrFactions[contactID]?.factionName {
					contactName = faction
					cell.subtitleLabel?.text = contactName
				}
				else {
					dataManager.contacts(ids: Set([Int64(contactID)])).then(on: .main) { result in
						let contact: NCContact? = {
							guard let objectID = result[Int64(contactID)] else {return nil}
							return (try? NCCache.sharedCache?.viewContext.existingObject(with: objectID)) as? NCContact
						}()
						self.contactName = contact?.name ?? NSLocalizedString("Unknown", comment: "")
						if (cell.object as? NCKillmail)?.killmailID == self.killmail.killmailID {
							cell.subtitleLabel?.text = self.contactName
						}
					}
				}
			}
			else {
				contactName = NSLocalizedString("Unknown", comment: "")
			}
		}
		else {
			cell.subtitleLabel?.text = contactName
		}
	}
	
	override var hash: Int {
		return killmail.killmailID
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCKillmailRow)?.hashValue == hashValue
	}
}
