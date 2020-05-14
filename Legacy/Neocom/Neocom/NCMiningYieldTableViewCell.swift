//
//  NCMiningYieldTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp

class NCMiningYieldTableViewCell: NCTableViewCell {
	@IBOutlet weak var minerLabel: UILabel!
	@IBOutlet weak var droneLabel: UILabel!
	@IBOutlet weak var totalLabel: UILabel!
}

extension Prototype {
	enum NCMiningYieldTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCMiningYieldTableViewCell")
	}
}

class NCMiningYieldRow: TreeRow {
	let ship: DGMShip
	
	init(ship: DGMShip) {
		self.ship = ship
		super.init(prototype: Prototype.NCMiningYieldTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCMiningYieldTableViewCell else {return}
		let ship = self.ship
		cell.object = ship
		let minerYield = ship.minerYield * DGMSeconds(1)
		let droneYield = ship.droneYield * DGMSeconds(1)
		let total = minerYield + droneYield;
		
		let formatter = NCUnitFormatter(unit: .none, style: .short, useSIPrefix: false)
		cell.minerLabel.text = formatter.string(for: minerYield)
		cell.droneLabel.text = formatter.string(for: droneYield)
		cell.totalLabel.text = formatter.string(for: total)
	}
	
	override var hash: Int {
		return ship.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCMiningYieldRow)?.hashValue == hashValue
	}
	
}
