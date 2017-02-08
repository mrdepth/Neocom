//
//  NCTankTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCTankStackView: UIStackView {
	@IBOutlet weak var shieldRechargeLabel: UILabel!
	@IBOutlet weak var shieldBoostLabel: UILabel!
	@IBOutlet weak var armorRepairLabel: UILabel!
	@IBOutlet weak var hullLabel: UILabel!
	@IBOutlet weak var effectiveShieldRechargeLabel: UILabel!
	@IBOutlet weak var effectiveSieldBoostLabel: UILabel!
	@IBOutlet weak var effectiveArmorRepairLabel: UILabel!
	@IBOutlet weak var effectiveHullLabel: UILabel!
}

class NCTankTableViewCell: NCTableViewCell {
	@IBOutlet weak var reinforcedView: NCTankStackView!
	@IBOutlet weak var sustainedView: NCTankStackView!
	
}
