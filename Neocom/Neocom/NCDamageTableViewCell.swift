//
//  NCDamageTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCDamageStackView: UIStackView {
	@IBOutlet weak var weaponLabel: UILabel!
	@IBOutlet weak var droneLabel: UILabel!
	@IBOutlet weak var totalLabel: UILabel!
}

class NCDamageTableViewCell: NCTableViewCell {
	@IBOutlet weak var damagePatternView: NCResistancesStackView!
	@IBOutlet weak var volleyView: NCDamageStackView!
	@IBOutlet weak var dpsView: NCDamageStackView!
}
