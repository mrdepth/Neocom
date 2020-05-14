//
//  NCResistancesTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import Dgmpp

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
	enum NCResistancesTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCResistancesTableViewCell")
	}
}

class NCResistancesRow: TreeRow {
	let ship: DGMShip
	let fleet: NCFittingFleet
	
	init(ship: DGMShip, fleet: NCFittingFleet) {
		self.ship = ship
		self.fleet = fleet
		super.init(prototype: Prototype.NCResistancesTableViewCell.default)
		route = Router.Fitting.DamagePatterns {[weak self] (controller, damagePattern) in
			self?.route?.unwind()
			guard let gang = ship.parent?.parent as? DGMGang else {return}
			for pilot in gang.pilots {
				pilot.ship?.damagePattern = damagePattern
			}
			NotificationCenter.default.post(name: Notification.Name.NCFittingFleetDidUpdate, object: self?.fleet)
		}
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCResistancesTableViewCell else {return}
		let ship = self.ship
		cell.object = ship

		let resistances = ship.resistances
		let damagePattern = ship.damagePattern
		let hp = ship.hitPoints
		let ehp = ship.effectiveHitPoints
		
		let formatter = NCUnitFormatter(unit: .none, style: .short, useSIPrefix: false)
		
		func fill(label: NCDamageTypeLabel, value: Double) {
			label.progress = Float(value)
			label.text = "\(Int(round(value * 100)))%"
		}
		
		func fill(view: NCResistancesStackView, vector: DGMDamageVector) {
			fill(label: view.emLabel, value: vector.em)
			fill(label: view.kineticLabel, value: vector.kinetic)
			fill(label: view.thermalLabel, value: vector.thermal)
			fill(label: view.explosiveLabel, value: vector.explosive)
		}
		
		fill(view: cell.shieldView, vector: DGMDamageVector(resistances.shield))
		fill(view: cell.armorView, vector: DGMDamageVector(resistances.armor))
		fill(view: cell.structureView, vector: DGMDamageVector(resistances.hull))
		fill(view: cell.damagePatternView, vector: damagePattern)
		cell.shieldView.hpLabel.text = formatter.string(for: hp.shield)
		cell.armorView.hpLabel.text = formatter.string(for: hp.armor)
		cell.structureView.hpLabel.text = formatter.string(for: hp.hull)
		let s = NCUnitFormatter.localizedString(from: ehp.armor + ehp.shield + ehp.hull, unit: .none, style: .full)
		cell.ehpLabel.text = NSLocalizedString("EHP", comment: "") + ": \(s)"
	}
	
	override var hash: Int {
		return ship.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCResistancesRow)?.hashValue == hashValue
	}
	
}
