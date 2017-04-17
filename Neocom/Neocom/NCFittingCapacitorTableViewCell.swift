//
//  NCFittingCapacitorTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

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
	let ship: NCFittingShip
	
	init(ship: NCFittingShip) {
		self.ship = ship
		super.init(prototype: Prototype.NCFittingCapacitorTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingCapacitorTableViewCell else {return}
		let ship = self.ship
		cell.object = ship
		ship.engine?.perform {
			let capCapacity = ship.capCapacity
			let isCapStable = ship.isCapStable
			let capState = isCapStable ? ship.capStableLevel : ship.capLastsTime
			let capRechargeTime = ship.capRechargeTime
			let delta = ship.capRecharge - ship.capUsed
			
			DispatchQueue.main.async {
				if cell.object as? NCFittingShip === ship {
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
