//
//  NCResistancesTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCResistancesStackView: UIStackView {
	@IBOutlet weak var emLabel: NCDamageTypeLabel!
	@IBOutlet weak var thermalLabel: NCDamageTypeLabel!
	@IBOutlet weak var kineticLabel: NCDamageTypeLabel!
	@IBOutlet weak var explosiveLabel: NCDamageTypeLabel!
	@IBOutlet weak var hpLabel: UILabel!
}

class NCResistancesTableViewCell: NCTableViewCell {
	@IBOutlet weak var shieldView: NCResistancesStackView!
	@IBOutlet weak var armorView: NCResistancesStackView!
	
	@IBOutlet weak var structureView: NCResistancesStackView!
	@IBOutlet weak var damagePatternView: NCResistancesStackView!
	@IBOutlet weak var ehpLabel: UILabel!
}

extension Prototype {
	struct NCResistancesTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCResistancesTableViewCell")
	}
}

class NCResistancesRow: TreeRow {
	let ship: NCFittingShip
	
	init(ship: NCFittingShip) {
		self.ship = ship
		super.init(prototype: Prototype.NCResistancesTableViewCell.default)
		route = Router.Fitting.DamagePatterns {[weak self] (controller, damagePattern) in
			self?.route?.unwind()
			ship.engine?.perform {
				guard let gang = ship.owner?.owner as? NCFittingGang else {return}
				for pilot in gang.pilots {
					pilot.ship?.damagePattern = damagePattern
				}
			}
		}
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCResistancesTableViewCell else {return}
		let ship = self.ship
		cell.object = ship
		ship.engine?.perform {
			let resistances = ship.resistances
			let damagePattern = ship.damagePattern
			let hp = ship.hitPoints
			let ehp = ship.effectiveHitPoints
			
			DispatchQueue.main.async {
				if cell.object as? NCFittingShip === ship {
					let formatter = NCUnitFormatter(unit: .none, style: .short, useSIPrefix: false)
					
					func fill(label: NCDamageTypeLabel, value: Double) {
						label.progress = Float(value)
						label.text = "\(Int(round(value * 100)))%"
					}
					
					func fill(view: NCResistancesStackView, vector: NCFittingDamage) {
						fill(label: view.emLabel, value: vector.em)
						fill(label: view.kineticLabel, value: vector.kinetic)
						fill(label: view.thermalLabel, value: vector.thermal)
						fill(label: view.explosiveLabel, value: vector.explosive)
					}
					
					fill(view: cell.shieldView, vector: resistances.shield)
					fill(view: cell.armorView, vector: resistances.armor)
					fill(view: cell.structureView, vector: resistances.hull)
					fill(view: cell.damagePatternView, vector: damagePattern)
					cell.shieldView.hpLabel.text = formatter.string(for: hp.shield)
					cell.armorView.hpLabel.text = formatter.string(for: hp.armor)
					cell.structureView.hpLabel.text = formatter.string(for: hp.hull)
					cell.ehpLabel.text = NSLocalizedString("EHP", comment: "") + ": \(formatter.string(for: ehp.armor + ehp.shield + ehp.hull) ?? "")"
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
