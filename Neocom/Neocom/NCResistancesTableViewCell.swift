//
//  NCResistancesTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCResistancesStackView: UIStackView {
	@IBOutlet weak var emLabel: NCDamageTypeLabel!
	@IBOutlet weak var thermalLabel: NCDamageTypeLabel!
	@IBOutlet weak var kineticLabel: NCDamageTypeLabel!
	@IBOutlet weak var explosiveLabel: NCDamageTypeLabel!
	@IBOutlet weak var hpLabel: UILabel!
}

class NCResistancesTableViewCell: NCTableViewCell {
	@IBOutlet weak var shieldView: NCResistancesStackView!
	@IBOutlet weak var armorView: NCResistancesStackView!
	
	@IBOutlet weak var structureView: NCResistancesStackView!
	@IBOutlet weak var damagePatternView: NCResistancesStackView!
	@IBOutlet weak var ehpLabel: UILabel!
}
