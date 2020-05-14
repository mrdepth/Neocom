//
//  NCTankTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import Dgmpp

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
	enum NCTankTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCTankTableViewCell")
	}
}


class NCTankRow: TreeRow {
	let ship: DGMShip
	
	init(ship: DGMShip) {
		self.ship = ship
		super.init(prototype: Prototype.NCTankTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCTankTableViewCell else {return}
		let ship = self.ship
		cell.object = ship
		let tank = (ship.tank, ship.effectiveTank)
		let sustainableTank = (ship.sustainableTank, ship.effectiveSustainableTank)
		
		let formatter = NCUnitFormatter(unit: .none, style: .short, useSIPrefix: false)
		
		func fill(view: NCTankStackView, tank: (DGMTank, DGMTank)) {
			view.shieldRechargeLabel.text = formatter.string(for: tank.0.passiveShield * DGMSeconds(1))
			view.effectiveShieldRechargeLabel.text = formatter.string(for: tank.1.passiveShield * DGMSeconds(1))
			view.shieldBoostLabel.text = formatter.string(for: tank.0.shieldRepair * DGMSeconds(1))
			view.effectiveSieldBoostLabel.text = formatter.string(for: tank.1.shieldRepair * DGMSeconds(1))
			view.armorRepairLabel.text = formatter.string(for: tank.0.armorRepair * DGMSeconds(1))
			view.effectiveArmorRepairLabel.text = formatter.string(for: tank.1.armorRepair * DGMSeconds(1))
			view.hullRepairLabel.text = formatter.string(for: tank.0.hullRepair * DGMSeconds(1))
			view.effectiveHullRepairLabel.text = formatter.string(for: tank.1.hullRepair * DGMSeconds(1))
		}
		
		fill(view: cell.reinforcedView, tank: tank)
		fill(view: cell.sustainedView, tank: sustainableTank)
	}
	
	override var hash: Int {
		return ship.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCTankRow)?.hashValue == hashValue
	}
	
}
