//
//  NCDamageTypeTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCDamageTypeTableViewCell: NCTableViewCell {
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var emLabel: NCDamageTypeLabel!
	@IBOutlet weak var thermalLabel: NCDamageTypeLabel!
	@IBOutlet weak var kineticLabel: NCDamageTypeLabel!
	@IBOutlet weak var explosiveLabel: NCDamageTypeLabel!
}
