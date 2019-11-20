//
//  NCChargeTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCChargeTableViewCell: NCTableViewCell {
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var emLabel: NCDamageTypeLabel!
	@IBOutlet weak var thermalLabel: NCDamageTypeLabel!
	@IBOutlet weak var kineticLabel: NCDamageTypeLabel!
	@IBOutlet weak var explosiveLabel: NCDamageTypeLabel!
}

extension Prototype {
	enum NCChargeTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCChargeTableViewCell", bundle: nil), reuseIdentifier: "NCChargeTableViewCell")
		static let compact = Prototype(nib: UINib(nibName: "NCChargeCompactTableViewCell", bundle: nil), reuseIdentifier: "NCChargeCompactTableViewCell")
	}
}


class NCChargeRow: TreeRow {
	let type: NCDBInvType
	
	init(prototype: Prototype = Prototype.NCChargeTableViewCell.default, type: NCDBInvType, route: Route? = nil, accessoryButtonRoute: Route? = nil) {
		self.type = type
		let p = type.dgmppItem?.damage == nil ? Prototype.NCDefaultTableViewCell.compact : prototype
		super.init(prototype: p, route: route, accessoryButtonRoute: accessoryButtonRoute)
	}
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCChargeTableViewCell {
			cell.titleLabel?.text = type.typeName
			cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.object = type
			if let damage = type.dgmppItem?.damage {
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
		else if let cell = cell as? NCDefaultTableViewCell {
			cell.titleLabel?.text = type.typeName
			cell.iconView?.image = type.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.object = type
		}
	}
	
	override var hashValue: Int {
		return type.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCChargeRow)?.hashValue == hashValue
	}
}
