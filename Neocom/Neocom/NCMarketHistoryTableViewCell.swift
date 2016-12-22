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

	@IBOutlet weak var pricesStackView: UIStackView!
	@IBOutlet weak var montshStackView: UIStackView!
	@IBOutlet weak var volumesStackView: UIStackView!
}
