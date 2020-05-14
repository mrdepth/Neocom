//
//  NCFittingCapacitorTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import Dgmpp

class NCFittingCapacitorTableViewCell: NCTableViewCell {
	@IBOutlet weak var capacityLabel: UILabel?
	@IBOutlet weak var stateLabel: UILabel?
	@IBOutlet weak var stateLevelLabel: UILabel?
	@IBOutlet weak var rechargeTimeLabel: UILabel?
	@IBOutlet weak var deltaLabel: UILabel?
	
}

extension Prototype {
	enum NCFittingCapacitorTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCFittingCapacitorTableViewCell")
	}
}

class NCFittingCapacitorRow: TreeRow {
	let ship: DGMShip
	
	init(ship: DGMShip) {
		self.ship = ship
		super.init(prototype: Prototype.NCFittingCapacitorTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingCapacitorTableViewCell else {return}
		let ship = self.ship
		cell.object = ship
		let capCapacity = ship.capacitor.capacity
		let isCapStable = ship.capacitor.isStable
		let capState = isCapStable ? ship.capacitor.stableLevel : ship.capacitor.lastsTime
		let capRechargeTime = ship.capacitor.rechargeTime
		let delta = (ship.capacitor.recharge - ship.capacitor.use) * DGMSeconds(1)
		
		cell.capacityLabel?.text = NCUnitFormatter.localizedString(from: capCapacity, unit: .gigaJoule, style: .full)
		cell.rechargeTimeLabel?.text = NCTimeIntervalFormatter.localizedString(from: capRechargeTime, precision: .seconds)
		cell.deltaLabel?.text = (delta > 0 ? "+" : "") + NCUnitFormatter.localizedString(from: delta, unit: .gigaJoulePerSecond, style: .full)
		if isCapStable {
			cell.stateLabel?.text = NSLocalizedString("Stable:", comment: "")
			cell.stateLevelLabel?.text = String(format:"%.1f%%", capState * 100)
		}
		else {
			cell.stateLabel?.text = NSLocalizedString("Lasts:", comment: "")
			cell.stateLevelLabel?.text = NCTimeIntervalFormatter.localizedString(from: capState, precision: .seconds)
		}
	}
	
	override var hash: Int {
		return ship.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingCapacitorRow)?.hashValue == hashValue
	}
	
}
