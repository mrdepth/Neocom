//
//  NCFirepowerTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCDamageStackView: UIStackView {
	@IBOutlet weak var weaponLabel: UILabel!
	@IBOutlet weak var droneLabel: UILabel!
	@IBOutlet weak var totalLabel: UILabel!
}

class NCFirepowerTableViewCell: NCTableViewCell {
	@IBOutlet weak var damagePatternView: NCResistancesStackView!
	@IBOutlet weak var volleyView: NCDamageStackView!
	@IBOutlet weak var dpsView: NCDamageStackView!
	
}

extension Prototype {
	struct NCFirepowerTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCFirepowerTableViewCell")
	}
}


class NCFirepowerRow: TreeRow {
	let ship: NCFittingShip
	
	init(ship: NCFittingShip) {
		self.ship = ship
		super.init(prototype: Prototype.NCFirepowerTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFirepowerTableViewCell else {return}
		let ship = self.ship
		cell.object = ship
		ship.engine?.perform {
			let weaponDPS = ship.weaponDPS
			let weaponVolley = ship.weaponVolley
			let droneDPS = ship.droneDPS
			let droneVolley = ship.droneVolley
			let dps = weaponDPS + droneDPS
			let volley = weaponVolley + droneVolley
			
			DispatchQueue.main.async {
				if cell.object as? NCFittingShip === ship {
					let formatter = NCUnitFormatter(unit: .none, style: .short, useSIPrefix: false)
					cell.dpsView.weaponLabel.text = formatter.string(for: weaponDPS.total)
					cell.dpsView.droneLabel.text = formatter.string(for: droneDPS.total)
					cell.dpsView.totalLabel.text = formatter.string(for: dps.total)
					cell.volleyView.weaponLabel.text = formatter.string(for: weaponVolley.total)
					cell.volleyView.droneLabel.text = formatter.string(for: droneVolley.total)
					cell.volleyView.totalLabel.text = formatter.string(for: volley.total)
					
					func fill(label: NCDamageTypeLabel, value: Double, total: Double) {
						label.progress = Float(value/total)
						label.text = formatter.string(for: value)
					}
					
					let total = dps.total
					fill(label: cell.damagePatternView.emLabel, value: dps.em, total: total)
					fill(label: cell.damagePatternView.kineticLabel, value: dps.kinetic, total: total)
					fill(label: cell.damagePatternView.thermalLabel, value: dps.thermal, total: total)
					fill(label: cell.damagePatternView.explosiveLabel, value: dps.explosive, total: total)
				}
			}
		}
	}
	
	override func move(from: TreeNode) -> TreeNodeReloading {
		return .reload
	}
	
	override var hashValue: Int {
		return ship.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingResourcesRow)?.hashValue == hashValue
	}
	
}
