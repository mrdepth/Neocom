//
//  InvTypeMarketOrderCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/26/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

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
		var prototype: Prototype = Prototype.InvTypeMarketOrderCell.default
		var price: Double
		var location: NSAttributedString
		var quantity: Int64
	}
}
