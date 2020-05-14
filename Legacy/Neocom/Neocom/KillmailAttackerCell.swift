//
//  KillmailAttackerCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/14/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import TreeController

class KillmailAttackerCell: RowCell {
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var subtitleLabel: UILabel?
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var shipImageView: UIImageView?
	@IBOutlet weak var shipLabel: UILabel?
	@IBOutlet weak var weaponLabel: UILabel?
}

extension Prototype {
	enum KillmailAttackerCell {
		static let `default` = Prototype(nib: UINib(nibName: "KillmailAttackerCell", bundle: nil), reuseIdentifier: "KillmailAttackerCell")
		static let npc = Prototype(nib: UINib(nibName: "KillmailAttackerNPCCell", bundle: nil), reuseIdentifier: "KillmailAttackerNPCCell")
	}
}

extension Tree.Item {
	
	class KillmailAttackerRow: Row<ESI.Killmails.Killmail.Attacker>, Routable {
		override var prototype: Prototype? {
			return character != nil ? Prototype.KillmailAttackerCell.default : Prototype.KillmailAttackerCell.npc
		}
		
		let character: Contact?
		let corporation: Contact?
		let alliance: Contact?
		
		lazy var faction = content.factionID.flatMap{Services.sde.viewContext.chrFaction($0)}
		
		lazy var shipType = content.shipTypeID.flatMap{Services.sde.viewContext.invType($0)}
		lazy var weaponType = content.weaponTypeID.flatMap{Services.sde.viewContext.invType($0)}

		
		var image: UIImage?
		var route: Routing?
		var api: API

		init(_ content: ESI.Killmails.Killmail.Attacker, contacts: [Int64: Contact]?, api: API) {
			character = content.characterID.flatMap{contacts?[Int64($0)]}
			corporation = content.corporationID.flatMap{contacts?[Int64($0)]}
			alliance = content.allianceID.flatMap{contacts?[Int64($0)]}
			self.api = api
			super.init(content)
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? KillmailAttackerCell else {return}
			
			let title = character?.name ?? corporation?.name ?? alliance?.name ?? faction?.factionName

			if content.finalBlow {
				cell.titleLabel?.attributedText = (title ?? "") + " [\(NSLocalizedString("final blow", comment: ""))]" * [NSAttributedString.Key.foregroundColor: UIColor.caption]
			}
			else {
				cell.titleLabel?.text = title
			}

			switch (corporation?.name, alliance?.name) {
			case let (a?, b?):
				cell.subtitleLabel?.text = "\(a) / \(b)"
			case let (a?, nil):
				cell.subtitleLabel?.text = a
			case let (nil, b):
				cell.subtitleLabel?.text = b
			}

			
			cell.accessoryType = route != nil ? .disclosureIndicator : .none
			
			cell.shipLabel?.text = shipType?.typeName
			cell.shipImageView?.image = shipType?.icon?.image?.image

			if let weapon = weaponType?.typeName, character != nil {
				cell.weaponLabel?.text = String(format: NSLocalizedString("%@ damage done with %@", comment: ""), UnitFormatter.localizedString(from: content.damageDone, unit: .none, style: .long), weapon)
			}
			else {
				cell.weaponLabel?.text = String(format: NSLocalizedString("%@ damage done", comment: ""), UnitFormatter.localizedString(from: content.damageDone, unit: .none, style: .long))
			}
			
			if image == nil, let size = cell.iconView?.bounds.size {
				if let contact = character ?? corporation ?? alliance {
					api.image(contact: contact, dimension: Int(size.width), cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self, weak treeController] result in
						guard let strongSelf = self else {return}
						strongSelf.image = result.value
						treeController?.reloadRow(for: strongSelf, with: .none)
					}.catch(on: .main) { [weak self] _ in
						self?.image = UIImage()
					}
				}
				else {
					image = faction?.icon?.image?.image ?? UIImage()
				}
			}
			
			cell.iconView?.image = image
		}
	}
}
