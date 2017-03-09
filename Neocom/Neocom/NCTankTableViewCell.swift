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
	@IBOutlet weak var hullRepairLabel: UILabel!
	@IBOutlet weak var effectiveShieldRechargeLabel: UILabel!
	@IBOutlet weak var effectiveSieldBoostLabel: UILabel!
	@IBOutlet weak var effectiveArmorRepairLabel: UILabel!
	@IBOutlet weak var effectiveHullRepairLabel: UILabel!
}

class NCTankTableViewCell: NCTableViewCell {
	@IBOutlet weak var reinforcedView: NCTankStackView!
	@IBOutlet weak var sustainedView: NCTankStackView!
	
}

extension Prototype {
	struct NCTankTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCTankTableViewCell")
	}
}


class NCTankRow: TreeRow {
	let ship: NCFittingShip
	
	init(ship: NCFittingShip) {
		self.ship = ship
		super.init(prototype: Prototype.NCTankTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCTankTableViewCell else {return}
		let ship = self.ship
		cell.object = ship
		ship.engine?.perform {
			let tank = (ship.tank, ship.effectiveTank)
			let sustainableTank = (ship.sustainableTank, ship.effectiveSustainableTank)
			
			DispatchQueue.main.async {
				if cell.object as? NCFittingShip === ship {
					let formatter = NCUnitFormatter(unit: .none, style: .short, useSIPrefix: false)
					
					func fill(view: NCTankStackView, tank: (NCFittingTank, NCFittingTank)) {
						view.shieldRechargeLabel.text = formatter.string(for: tank.0.passiveShield)
						view.effectiveShieldRechargeLabel.text = formatter.string(for: tank.1.passiveShield)
						view.shieldBoostLabel.text = formatter.string(for: tank.0.shieldRepair)
						view.effectiveSieldBoostLabel.text = formatter.string(for: tank.1.shieldRepair)
						view.armorRepairLabel.text = formatter.string(for: tank.0.armorRepair)
						view.effectiveArmorRepairLabel.text = formatter.string(for: tank.1.armorRepair)
						view.hullRepairLabel.text = formatter.string(for: tank.0.hullRepair)
						view.effectiveHullRepairLabel.text = formatter.string(for: tank.1.hullRepair)
					}
					
					fill(view: cell.reinforcedView, tank: tank)
					fill(view: cell.sustainedView, tank: sustainableTank)
				}
			}
		}
	}
	
	override func transitionStyle(from node: TreeNode) -> TransitionStyle {
		return .reload
	}

	override var hashValue: Int {
		return ship.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingResourcesRow)?.hashValue == hashValue
	}
	
}
