//
//  NCMiningYieldTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

class NCMiningYieldTableViewCell: NCTableViewCell {
	@IBOutlet weak var minerLabel: UILabel!
	@IBOutlet weak var droneLabel: UILabel!
	@IBOutlet weak var totalLabel: UILabel!
}

extension Prototype {
	struct NCMiningYieldTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCMiningYieldTableViewCell")
	}
}

class NCMiningYieldRow: TreeRow {
	let ship: NCFittingShip
	
	init(ship: NCFittingShip) {
		self.ship = ship
		super.init(prototype: Prototype.NCMiningYieldTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCMiningYieldTableViewCell else {return}
		let ship = self.ship
		cell.object = ship
		ship.engine?.perform {
			let minerYield = ship.minerYield
			let droneYield = ship.droneYield
			let total = minerYield + droneYield;
			
			DispatchQueue.main.async {
				if cell.object as? NCFittingShip === ship {
					let formatter = NCUnitFormatter(unit: .none, style: .short, useSIPrefix: false)
					cell.minerLabel.text = formatter.string(for: minerYield)
					cell.droneLabel.text = formatter.string(for: droneYield)
					cell.totalLabel.text = formatter.string(for: total)
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
		return (object as? NCMiningYieldRow)?.hashValue == hashValue
	}
	
}
