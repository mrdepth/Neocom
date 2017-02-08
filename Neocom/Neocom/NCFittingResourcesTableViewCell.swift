//
//  NCFittingResourcesTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingResourcesTableViewCell: NCTableViewCell {
	@IBOutlet weak var powerGridLabel: NCResourceLabel?
	@IBOutlet weak var cpuLabel: NCResourceLabel?
	@IBOutlet weak var calibrationLabel: UILabel?
	@IBOutlet weak var turretsLabel: UILabel?
	@IBOutlet weak var launchersLabel: UILabel?
	@IBOutlet weak var droneBayLabel: NCResourceLabel?
	@IBOutlet weak var droneBandwidthLabel: NCResourceLabel?
	@IBOutlet weak var dronesCountLabel: UILabel?

}
