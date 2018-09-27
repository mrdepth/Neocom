//
//  InvTypeMarketOrderCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/26/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class InvTypeMarketOrderCell: RowCell {
	@IBOutlet weak var priceLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var quantityLabel: UILabel!

}

extension Prototype {
	enum InvTypeMarketOrderCell {
		static let `default` = Prototype(nib: UINib(nibName: "InvTypeMarketOrderCell", bundle: nil), reuseIdentifier: "InvTypeMarketOrderCell")
	}
}

extension Tree.Content {
	struct InvTypeMarketOrder: Hashable {
		var prototype: Prototype? = Prototype.InvTypeMarketOrderCell.default
		var order: ESI.Market.Order
		var location: NSAttributedString?
	}
}

extension Tree.Content.InvTypeMarketOrder: CellConfiguring {
	func configure(cell: UITableViewCell) {
		guard let cell = cell as? InvTypeMarketOrderCell else {return}
		
		cell.priceLabel.text = UnitFormatter.localizedString(from: order.price, unit: .isk, style: .long)
		cell.quantityLabel.text = UnitFormatter.localizedString(from: order.volumeRemain, unit: .none, style: .long)
		cell.locationLabel.attributedText = location ?? NSAttributedString(string: NSLocalizedString("Unknown location", comment: ""))
	}
}
