//
//  NCChargeTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCChargeTableViewCell: NCDamageTypeTableViewCell {
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var titleLabel: UILabel?

}

class NCChargeRow: TreeRow {
	lazy var type: NCDBInvType? = {
		guard self.typeID > 0 else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[self.typeID]
	}()
	var typeID: Int = 0
	
	init(type: NCDBInvType, segue: String? = nil, accessoryButtonSegue: String? = nil) {
		super.init(cellIdentifier: "NCChargeTableViewCell", segue: segue, accessoryButtonSegue: accessoryButtonSegue)
		self.type = type
	}
	
	init(typeID: Int, segue: String? = nil, accessoryButtonSegue: String? = nil) {
		self.typeID = typeID
		super.init(cellIdentifier: "NCChargeTableViewCell", segue: segue, accessoryButtonSegue: accessoryButtonSegue)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCChargeTableViewCell else {return}
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.object = type
		if let damage = type?.dgmppItem?.damage {
			var total = damage.emAmount + damage.kineticAmount + damage.thermalAmount + damage.explosiveAmount
			if total == 0 {
				total = 1
			}
			
			cell.emLabel.progress = damage.emAmount / total
			cell.emLabel.text = NCUnitFormatter.localizedString(from: damage.emAmount, unit: .none, style: .short)

			cell.kineticLabel.progress = damage.kineticAmount / total
			cell.kineticLabel.text = NCUnitFormatter.localizedString(from: damage.kineticAmount, unit: .none, style: .short)

			cell.thermalLabel.progress = damage.thermalAmount / total
			cell.thermalLabel.text = NCUnitFormatter.localizedString(from: damage.thermalAmount, unit: .none, style: .short)

			cell.explosiveLabel.progress = damage.explosiveAmount / total
			cell.explosiveLabel.text = NCUnitFormatter.localizedString(from: damage.explosiveAmount, unit: .none, style: .short)
			
		}
		else {
			for label in [cell.emLabel, cell.kineticLabel, cell.thermalLabel, cell.explosiveLabel] {
				label?.progress = 0
				label?.text = "0"
			}
		}
	}
}
