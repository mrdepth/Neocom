//
//  NCFittingResourcesTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import Dgmpp

class NCFittingResourcesTableViewCell: NCTableViewCell {
	@IBOutlet weak var powerGridLabel: NCResourceLabel?
	@IBOutlet weak var cpuLabel: NCResourceLabel?
	@IBOutlet weak var calibrationLabel: UILabel?
	@IBOutlet weak var turretsLabel: UILabel?
	@IBOutlet weak var launchersLabel: UILabel?
	@IBOutlet weak var droneBayLabel: NCResourceLabel?
	@IBOutlet weak var droneBandwidthLabel: NCResourceLabel?
	@IBOutlet weak var dronesCountLabel: UILabel?

	override func awakeFromNib() {
		super.awakeFromNib()
		powerGridLabel?.unit = .megaWatts
		cpuLabel?.unit = .teraflops
		droneBayLabel?.unit = .cubicMeter
		droneBandwidthLabel?.unit = .megaBitsPerSecond
	}
}

extension Prototype {
	enum NCFittingResourcesTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCFittingResourcesTableViewCell")
	}
}

class NCFittingResourcesRow: TreeRow {
	let ship: DGMShip
	
	init(ship: DGMShip) {
		self.ship = ship
		super.init(prototype: Prototype.NCFittingResourcesTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingResourcesTableViewCell else {return}
		let ship = self.ship
		cell.object = ship
		let powerGrid = (ship.usedPowerGrid, ship.totalPowerGrid)
		let cpu = (ship.usedCPU, ship.totalCPU)
		let calibration = (ship.usedCalibration, ship.totalCalibration)
		let turrets = (ship.usedHardpoints(.turret), ship.totalHardpoints(.turret))
		let launchers = (ship.usedHardpoints(.launcher), ship.totalHardpoints(.launcher))
		
		let isCarrier = ship.totalFighterLaunchTubes > 0
		let droneBay = isCarrier ? (ship.usedFighterHangar, ship.totalFighterHangar) : (ship.usedDroneBay, ship.totalDroneBay)
		let droneBandwidth = (ship.usedDroneBandwidth, ship.totalDroneBandwidth)
		let droneSquadron = isCarrier ? (ship.usedFighterLaunchTubes, ship.totalFighterLaunchTubes) : (ship.usedDroneSquadron(.none), ship.totalDroneSquadron(.none))
		
		cell.powerGridLabel?.value = powerGrid.0
		cell.powerGridLabel?.maximumValue = powerGrid.1
		cell.cpuLabel?.value = cpu.0
		cell.cpuLabel?.maximumValue = cpu.1
		cell.calibrationLabel?.text = "\(Int(calibration.0))/\(Int(calibration.1))"
		
		cell.turretsLabel?.text = "\(turrets.0)/\(turrets.1)"
		cell.launchersLabel?.text = "\(launchers.0)/\(launchers.1)"
		cell.turretsLabel?.textColor = turrets.0 > turrets.1 ? .red : .white
		cell.launchersLabel?.textColor = launchers.0 > launchers.1 ? .red : .white
		
		cell.droneBayLabel?.value = droneBay.0
		cell.droneBayLabel?.maximumValue = droneBay.1
		cell.droneBandwidthLabel?.value = droneBandwidth.0
		cell.droneBandwidthLabel?.maximumValue = droneBandwidth.1
		cell.dronesCountLabel?.text = "\(droneSquadron.0)/\(droneSquadron.1)"
		cell.dronesCountLabel?.textColor = droneSquadron.0 > droneSquadron.1 ? .red : .white
	}
	
	override var hashValue: Int {
		return ship.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingResourcesRow)?.hashValue == hashValue
	}

}
