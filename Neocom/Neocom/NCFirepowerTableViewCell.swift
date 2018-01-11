//
//  NCFirepowerTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import Dgmpp

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
	enum NCFirepowerTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCFirepowerTableViewCell")
	}
}


class NCFirepowerRow: TreeRow {
	let ship: DGMShip
	
	init(ship: DGMShip) {
		self.ship = ship
		super.init(prototype: Prototype.NCFirepowerTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFirepowerTableViewCell else {return}
		let ship = self.ship
		cell.object = ship
		let weaponDPS = ship.turretsDPS() * DGMSeconds(1) + ship.launchersDPS() * DGMSeconds(1)
		let weaponVolley = ship.turretsVolley + ship.launchersVolley
		let droneDPS = ship.dronesDPS() * DGMSeconds(1)
		let dronesVolley = ship.dronesVolley
		let dps = weaponDPS + droneDPS
		let volley = weaponVolley + dronesVolley
			
		let formatter = NCUnitFormatter(unit: .none, style: .full, useSIPrefix: false)
		cell.dpsView.weaponLabel.text = formatter.string(for: weaponDPS.total)
		cell.dpsView.droneLabel.text = formatter.string(for: droneDPS.total)
		cell.dpsView.totalLabel.text = formatter.string(for: dps.total)
		cell.volleyView.weaponLabel.text = formatter.string(for: weaponVolley.total)
		cell.volleyView.droneLabel.text = formatter.string(for: dronesVolley.total)
		cell.volleyView.totalLabel.text = formatter.string(for: volley.total)
		
		func fill(label: NCDamageTypeLabel, value: Double, total: Double) {
			label.progress = fabs(total) > Double.leastNormalMagnitude ? Float(value/total) : 0
			label.text = formatter.string(for: value)
		}
		
		let total = dps.total
		fill(label: cell.damagePatternView.emLabel, value: dps.em, total: total)
		fill(label: cell.damagePatternView.kineticLabel, value: dps.kinetic, total: total)
		fill(label: cell.damagePatternView.thermalLabel, value: dps.thermal, total: total)
		fill(label: cell.damagePatternView.explosiveLabel, value: dps.explosive, total: total)
	}
	
	override var hashValue: Int {
		return ship.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFirepowerRow)?.hashValue == hashValue
	}
	
}
