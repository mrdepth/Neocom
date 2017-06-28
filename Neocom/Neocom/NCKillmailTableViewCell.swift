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
	
}

extension Prototype {
	enum NCKillmailTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCKillmailTableViewCell", bundle: nil), reuseIdentifier: "NCKillmailTableViewCell")
	}
}

class NCKillmailRow: TreeRow {
	
	let killmail: ESI.Killmails.Killmail?
	let zKillmail: ZKillboard.Killmail?
	let dataManager: NCDataManager
	let characterID: Int64?
	
	lazy var type: NCDBInvType? = {
		guard let shipTypeID = self.killmail?.victim.shipTypeID ?? self.zKillmail?.victim.shipTypeID else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[shipTypeID]
	}()
	
	init(killmail: ESI.Killmails.Killmail, characterID: Int64, dataManager: NCDataManager) {
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
	}

	var contactName: String?
	lazy var date: String = {
		let date = self.killmail?.killmailTime ?? self.zKillmail?.killmailTime ?? Date()
		return DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .medium)
	}()
	
	var subtitle: String {
		let count = killmail?.attackers.count ?? zKillmail?.attackers.count ?? 0
		if let contactName = self.contactName {
			return contactName + ", " + String(format: NSLocalizedString("%@ involved", comment: ""), NCUnitFormatter.localizedString(from: count, unit: .none, style: .full))
		}
		else {
			return String(format: NSLocalizedString("%@ involved", comment: ""), NCUnitFormatter.localizedString(from: count, unit: .none, style: .full))
		}
	}
	
	override func configure(cell: UITableViewCell) {
		
		guard let cell = cell as? NCKillmailTableViewCell else {return}
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.titleLabel?.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		cell.object = killmail
		cell.dateLabel.text = date
		
		if contactName == nil {
			cell.subtitleLabel?.text = subtitle
			
			let contactID: Int?
			
			if let killmail = killmail, let characterID = characterID {
				contactID = killmail.victim.characterID != Int(characterID) ? killmail.victim.characterID
					: {
						guard let attacker = killmail.attackers.first (where: {$0.finalBlow}) ?? killmail.attackers.first else {return nil}
						return attacker.characterID ?? attacker.corporationID ?? attacker.allianceID ?? attacker.factionID
						
					}()
			}
			else {
				contactID = zKillmail?.victim.characterID
			}
			
			if let contactID = contactID {
				if let faction = NCDatabase.sharedDatabase?.chrFactions[contactID]?.factionName {
					contactName = faction
					cell.subtitleLabel?.text = subtitle
				}
				else {
					dataManager.contacts(ids: Set([Int64(contactID)])) { result in
						let contact = result[Int64(contactID)]
						if contact?.name == nil {
							print ("\(contactID)")
						}
						self.contactName = contact?.name ?? NSLocalizedString("Unknown", comment: "")
						if (cell.object as? ESI.Killmails.Killmail) == self.killmail {
							cell.subtitleLabel?.text = self.subtitle
						}
					}
				}
			}
			else {
				contactName = NSLocalizedString("Unknown", comment: "")
			}
		}
		else {
			cell.subtitleLabel?.text = subtitle
		}
	}
	
	override var hashValue: Int {
		return killmail?.killmailID ?? zKillmail?.killmailID ?? 0
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCKillmailRow)?.hashValue == hashValue
	}
}
