//
//  NCFittingMiscTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingMiscTableViewCell: NCTableViewCell {
	
	@IBOutlet weak var targetsLabel: UILabel?
	@IBOutlet weak var targetingRangeLabel: UILabel?
	@IBOutlet weak var scanResolution: UILabel?
	@IBOutlet weak var sensorStrengthLabel: UILabel?
	@IBOutlet weak var sensorImageView: UIImageView?
	@IBOutlet weak var droneRangeLabel: UILabel?
	@IBOutlet weak var massLabel: UILabel?
	@IBOutlet weak var speedLabel: UILabel?
	@IBOutlet weak var alignTimeLabel: UILabel?
	@IBOutlet weak var signatureLabel: UILabel?
	@IBOutlet weak var cargoLabel: UILabel?
	@IBOutlet weak var oreHoldLabel: UILabel?
	@IBOutlet weak var warpSpeedLabel: UILabel?
}

class NCFittingMiscRow: TreeRow {
	let ship: NCFittingShip
	
	init(ship: NCFittingShip) {
		self.ship = ship
		super.init(cellIdentifier: "NCFittingMiscTableViewCell")
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingMiscTableViewCell else {return}
		let ship = self.ship
		cell.object = ship
		ship.engine?.perform {
			let maxTargets = ship.maxTargets
			let maxTargetRange = ship.maxTargetRange
			let scanResolution = ship.scanResolution
			let scanStrength = ship.scanStrength
			let scanType = ship.scanType
			let droneControlDistance = (ship.owner as? NCFittingCharacter)?.droneControlDistance ?? 0
			let mass = ship.mass
			let velocity = ship.velocity
			let alignTime = ship.alignTime
			let signatureRadius = ship.signatureRadius
			let capacity = ship.capacity
			let oreHoldCapacity = ship.oreHoldCapacity
			let warpSpeed = ship.warpSpeed
			
			DispatchQueue.main.async {
				if cell.object as? NCFittingShip === ship {
					cell.targetsLabel?.text = String(maxTargets)
					cell.targetingRangeLabel?.text = NCUnitFormatter.localizedString(from: maxTargetRange, unit: .meter, style: .short)
					cell.scanResolution?.text = NCUnitFormatter.localizedString(from: scanResolution, unit: .millimeter, style: .full)
					cell.sensorStrengthLabel?.text = String(Int(scanStrength))
					cell.sensorImageView?.image = scanType.image
					cell.droneRangeLabel?.text = NCUnitFormatter.localizedString(from: droneControlDistance, unit: .meter, style: .short)
					cell.massLabel?.text = NCUnitFormatter.localizedString(from: mass, unit: .kilogram, style: .short)
					cell.speedLabel?.text = NCUnitFormatter.localizedString(from: velocity, unit: .meterPerSecond, style: .short)
					cell.alignTimeLabel?.text = NCTimeIntervalFormatter.localizedString(from: alignTime, precision: .seconds)
					cell.signatureLabel?.text = String(Int(signatureRadius))
					cell.cargoLabel?.text = NCUnitFormatter.localizedString(from: capacity, unit: .cubicMeter, style: .short)
					cell.oreHoldLabel?.text = NCUnitFormatter.localizedString(from: oreHoldCapacity, unit: .cubicMeter, style: .short)
					cell.warpSpeedLabel?.text = NCUnitFormatter.localizedString(from: warpSpeed, unit: .auPerSecond, style: .short)
				}
			}
		}
	}
	
	override func changed(from: TreeNode) -> Bool {
		return true
	}
	
	override var hashValue: Int {
		return ship.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingResourcesRow)?.hashValue == hashValue
	}
	
}
