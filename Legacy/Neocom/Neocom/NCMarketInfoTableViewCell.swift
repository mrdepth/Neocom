//
//  NCMarketInfoTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCMarketInfoTableViewCell: NCTableViewCell {
	@IBOutlet weak var priceLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var quantityLabel: UILabel!

}

extension Prototype {
	enum NCMarketInfoTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCMarketInfoTableViewCell")
	}
}
