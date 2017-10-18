//
//  NCMarketHistoryTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCMarketHistoryTableViewCell: NCTableViewCell {
	@IBOutlet weak var marketHistoryView: NCMarketHistoryView!
}

extension Prototype {
	enum NCMarketHistoryTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCMarketHistoryTableViewCell")
	}
}
