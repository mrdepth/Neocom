//
//  NCMarketOrderTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCMarketOrderTableViewCell: NCTableViewCell {
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
	enum NCMarketOrderTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCMarketOrderTableViewCell")
	}
}

class NCMarketOrderRow: TreeRow {
	let order: ESI.Market.CharacterOrder
	let location: NCLocation?
	let expired: Date
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.order.typeID]
	}()
	
	init(order: ESI.Market.CharacterOrder, location: NCLocation?) {
		self.order = order
		self.location = location
		expired = order.issued + TimeInterval(order.duration * 3600 * 24)
		
		super.init(prototype: Prototype.NCMarketOrderTableViewCell.default, route: Router.Database.TypeInfo(order.typeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCMarketOrderTableViewCell else {return}
		cell.titleLabel.text = type?.typeName ?? NSLocalizedString("Unknown Type", comment: "")
		cell.subtitleLabel.attributedText = location?.displayName ?? NSLocalizedString("Unknown Location", comment: "") * [NSAttributedStringKey.foregroundColor: UIColor.lightText]
		cell.iconView.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.priceLabel.text = NCUnitFormatter.localizedString(from: order.price, unit: .isk, style: .full)
		cell.qtyLabel.text = NCUnitFormatter.localizedString(from: order.volumeRemain, unit: .none, style: .full) + "/" + NCUnitFormatter.localizedString(from: order.volumeTotal, unit: .none, style: .full)
		cell.issuedLabel.text = DateFormatter.localizedString(from: order.issued, dateStyle: .medium, timeStyle: .medium)
		
		let color = order.state == .open ? UIColor.white : UIColor.lightText
		cell.titleLabel.textColor = color
		cell.priceLabel.textColor = color
		cell.qtyLabel.textColor = color
		cell.issuedLabel.textColor = color
		cell.timeLeftLabel.textColor = color
		
		switch order.state {
		case .open:
			cell.stateLabel.text = NSLocalizedString("Open", comment: "") + ":"
			let t = expired.timeIntervalSinceNow
			cell.timeLeftLabel.text =  String(format: NSLocalizedString("Expires in %@", comment: ""), NCTimeIntervalFormatter.localizedString(from: max(t, 0), precision: .minutes))
		case .cancelled:
			cell.stateLabel.text = NSLocalizedString("Cancelled", comment: "") + ":"
			cell.timeLeftLabel.text = DateFormatter.localizedString(from: expired, dateStyle: .medium, timeStyle: .medium)
		case .characterDeleted:
			cell.stateLabel.text = NSLocalizedString("Deleted", comment: "") + ":"
			cell.timeLeftLabel.text = DateFormatter.localizedString(from: expired, dateStyle: .medium, timeStyle: .medium)
		case .closed:
			cell.stateLabel.text = NSLocalizedString("Closed", comment: "") + ":"
			cell.timeLeftLabel.text = DateFormatter.localizedString(from: expired, dateStyle: .medium, timeStyle: .medium)
		case .expired:
			cell.stateLabel.text = NSLocalizedString("Expired", comment: "") + ":"
			cell.timeLeftLabel.text = DateFormatter.localizedString(from: expired, dateStyle: .medium, timeStyle: .medium)
		case .pending:
			cell.stateLabel.text = NSLocalizedString("Pending", comment: "") + ":"
			cell.timeLeftLabel.text = " "
		}
	}
	
	override lazy var hashValue: Int = order.hashValue
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCMarketOrderRow)?.hashValue == hashValue
	}
}

