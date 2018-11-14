//
//  KillmailCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/13/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import TreeController

class KillmailCell: RowCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var solarSystemLabel: UILabel!
}

extension Prototype {
	enum KillmailCell {
		static let `default` = Prototype(nib: UINib(nibName: "KillmailCell", bundle: nil), reuseIdentifier: "KillmailCell")
	}
}

extension Tree.Item {
	class KillmailRow: RoutableRow<ESI.Killmails.Killmail> {
		lazy var type: SDEInvType? = Services.sde.viewContext.invType(content.victim.shipTypeID)
		lazy var location: EVELocation = Services.sde.viewContext.mapSolarSystem(content.solarSystemID).map{EVELocation($0)} ?? .unknown
		var name: Contact?
		
		override var prototype: Prototype? {
			return Prototype.KillmailCell.default
		}
		
		init(_ content: ESI.Killmails.Killmail, name: Contact?) {
			self.name = name
			super.init(content, route: Router.KillReports.killmailInfo(content))
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? KillmailCell else {return}
			
			cell.iconView?.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
			cell.titleLabel?.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
			cell.dateLabel.text = DateFormatter.localizedString(from: content.killmailTime, dateStyle: .none, timeStyle: .medium)
			cell.solarSystemLabel.attributedText = location.displayName + " (\(String(format: NSLocalizedString("%@ involved", comment: ""), UnitFormatter.localizedString(from: content.attackers.count, unit: .none, style: .long))))"
			cell.subtitleLabel.text = name?.name ?? NSLocalizedString("Unknown", comment: "")
		}
	}
}
