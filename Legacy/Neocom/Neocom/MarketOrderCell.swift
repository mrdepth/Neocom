//
//  MarketOrderCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/9/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import TreeController

class MarketOrderCell: RowCell {
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var stateLabel: UILabel!
	@IBOutlet weak var timeLeftLabel: UILabel!
	@IBOutlet weak var priceLabel: UILabel!
	@IBOutlet weak var qtyLabel: UILabel!
	@IBOutlet weak var issuedLabel: UILabel!
}

extension Prototype {
	enum MarketOrderCell {
		static let `default` = Prototype(nib: UINib(nibName: "MarketOrderCell", bundle: nil), reuseIdentifier: "MarketOrderCell")
	}
}

extension Tree.Item {
	class MarketOrderRow: RoutableRow<ESI.Market.CharacterOrder> {
		
		override var prototype: Prototype? {
			return Prototype.MarketOrderCell.default
		}
		
		let location: EVELocation?
		let expired: Date
		lazy var type: SDEInvType? = Services.sde.viewContext.invType(content.typeID)
		
		
		init(_ content: ESI.Market.CharacterOrder, location: EVELocation?) {
			self.location = location
			expired = content.issued + TimeInterval(content.duration * 3600 * 24)
			super.init(content, route: Router.SDE.invTypeInfo(.typeID(content.typeID)))
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? MarketOrderCell else {return}
			cell.titleLabel.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
			cell.subtitleLabel.attributedText = (location ?? .unknown).displayName
			cell.iconView.image = type?.icon?.image?.image ?? Services.sde.viewContext.eveIcon(.defaultType)?.image?.image
			cell.priceLabel.text = UnitFormatter.localizedString(from: content.price, unit: .isk, style: .long)
			cell.qtyLabel.text = UnitFormatter.localizedString(from: content.volumeRemain, unit: .none, style: .long) + "/" + UnitFormatter.localizedString(from: content.volumeTotal, unit: .none, style: .long)
			cell.issuedLabel.text = DateFormatter.localizedString(from: content.issued, dateStyle: .medium, timeStyle: .medium)
			cell.stateLabel.text = NSLocalizedString("Open", comment: "") + ":"
			
			let t = expired.timeIntervalSinceNow
			cell.timeLeftLabel.text =  String(format: NSLocalizedString("Expires in %@", comment: ""), TimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes))

		}
	}
}
