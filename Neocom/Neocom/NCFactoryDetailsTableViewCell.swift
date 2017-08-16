//
//  NCFactoryDetailsTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 16.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFactoryDetailsTableViewCell: NCTableViewCell {
	@IBOutlet weak var efficiencyLabel: UILabel!
	@IBOutlet weak var extrapolatedEfficiencyLabel: UILabel!
}

extension Prototype {
	enum NCFactoryDetailsTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCFactoryDetailsTableViewCell", bundle: nil), reuseIdentifier: "NCFactoryDetailsTableViewCell")
	}
}

class NCFactoryDetailsRow: TreeRow {
	let currentTime: TimeInterval

	let productionTime: TimeInterval?
	let idleTime: TimeInterval?
	let efficiency: Double?

	let extrapolatedProductionTime: TimeInterval?
	let extrapolatedIdleTime: TimeInterval?
	let extrapolatedEfficiency: Double?
	
	let identifier: Int64
	
	init(factory: NCFittingIndustryFacility, currentTime: TimeInterval) {
		self.currentTime = currentTime
		identifier = factory.identifier
		
		let states = factory.states as? [NCFittingProductionState]
		let lastState = states?.reversed().first {$0.currentCycle == nil}
		let firstProductionState = states?.first {$0.currentCycle?.launchTime == $0.timestamp}
//		let lastProductionState = states?.reversed().first {$0.currentCycle?.launchTime == $0.timestamp}
		let currentState = states?.reversed().first {$0.timestamp < currentTime} ?? states?.last

		efficiency = currentState?.efficiency
		extrapolatedEfficiency = lastState?.efficiency
		
		(productionTime, idleTime) = {
			guard let currentState = currentState, let firstProductionState = firstProductionState else {return (nil, nil)}
			let duration = currentState.timestamp - firstProductionState.timestamp
			let productionTime = currentState.efficiency * duration
			let idleTime = duration - productionTime
			return (productionTime, idleTime)
		}()
		
		(extrapolatedProductionTime, extrapolatedIdleTime) = {
			guard let lastState = lastState, let firstProductionState = firstProductionState else {return (nil, nil)}
			let duration = lastState.timestamp - firstProductionState.timestamp
			let productionTime = lastState.efficiency * duration
			let idleTime = duration - productionTime
			return (productionTime, idleTime)
		}()
		
		super.init(prototype: Prototype.NCFactoryDetailsTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFactoryDetailsTableViewCell else {return}

		if let productionTime = productionTime, let idleTime = idleTime, productionTime + idleTime > 0 {
			let duration = productionTime + idleTime
			cell.efficiencyLabel.text = String(format: "%.0f%%", productionTime / duration * 100)
		}
		else {
			cell.efficiencyLabel.text = "0%"
		}

		if let productionTime = extrapolatedProductionTime, let idleTime = extrapolatedIdleTime, productionTime + idleTime > 0 {
			let duration = productionTime + idleTime
			cell.extrapolatedEfficiencyLabel.text = String(format: "%.0f%%", productionTime / duration * 100)
		}
		else {
			cell.extrapolatedEfficiencyLabel.text = "0%"
		}

	}
	
	override var hashValue: Int {
		return identifier.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFactoryDetailsRow)?.hashValue == hashValue
	}
	
}
