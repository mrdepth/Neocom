//
//  NCExtractorDetailsTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCExtractorDetailsTableViewCell: NCTableViewCell {
	@IBOutlet weak var sumLabel: UILabel!
	@IBOutlet weak var yieldLabel: UILabel!
	@IBOutlet weak var cycleTimeLabel: UILabel!
	@IBOutlet weak var currentCycleLabel: UILabel!
	@IBOutlet weak var depletionLabel: UILabel!
}

extension Prototype {
	enum NCExtractorDetailsTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCExtractorDetailsTableViewCell", bundle: nil), reuseIdentifier: "NCExtractorDetailsTableViewCell")
	}
}

class NCExtractorDetailsRow: TreeRow {
	let currentTime: TimeInterval
	let yield: Int
	let waste: Int
	let currentState: NCFittingProductionState?
	let wasteState: NCFittingProductionState?
	let extractor: NCFittingExtractorControlUnit
	let identifier: Int64

	init(extractor: NCFittingExtractorControlUnit, currentTime: TimeInterval) {
		self.extractor = extractor
		self.currentTime = currentTime
		identifier = extractor.identifier
		
		let states = (extractor.states as? [NCFittingProductionState])?.filter{$0.currentCycle as? NCFittingProductionCycle != nil} ?? []
		
		(yield, waste) = states.flatMap {$0.currentCycle as? NCFittingProductionCycle}.reduce((0,0)) {
			($0.0 + $1.yield.quantity, $0.1 + $1.waste.quantity)
		}
		
		currentState = states.first {($0.timestamp...($0.timestamp + $0.currentCycle!.cycleTime)).contains(currentTime)}
		wasteState = states.first {$0.timestamp > currentTime && ($0.currentCycle as! NCFittingProductionCycle).waste.quantity > 0}
		
		super.init(prototype: Prototype.NCExtractorDetailsTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCExtractorDetailsTableViewCell else {return}
		let sum = yield + waste
		
		let extractor = self.extractor
		let currentTime = self.currentTime
		let currentState = self.currentState
		extractor.engine?.performBlockAndWait {
			cell.sumLabel.text = NCUnitFormatter.localizedString(from: sum, unit: .none, style: .full)
			
			let duration = extractor.expiryTime - extractor.installTime
			
			cell.yieldLabel.text = duration > 0 ? NCUnitFormatter.localizedString(from: Double(sum) / (duration / 3600), unit: .none, style: .full) : "0"
			
			
			let remains = extractor.expiryTime - currentTime
			cell.cycleTimeLabel.text = NCTimeIntervalFormatter.localizedString(from: currentState?.currentCycle?.cycleTime ?? 0, precision: .hours, format: .colonSeparated)

			if let currentState = currentState, let cycle = currentState.currentCycle as? NCFittingProductionCycle, remains > 0 {
				let t = currentTime.clamped(to: cycle.launchTime...(cycle.launchTime + cycle.cycleTime)) - cycle.launchTime
				cell.currentCycleLabel.text = NCTimeIntervalFormatter.localizedString(from: t, precision: .hours, format: .colonSeparated)
				cell.depletionLabel.text = NCTimeIntervalFormatter.localizedString(from: remains, precision: .minutes)
				cell.depletionLabel.textColor = remains < 3600 * 24 ? .yellow : .white
			}
			else {
				cell.currentCycleLabel.text = NCTimeIntervalFormatter.localizedString(from: 0, precision: .hours, format: .colonSeparated)
				cell.depletionLabel.text = NCTimeIntervalFormatter.localizedString(from: 0, precision: .hours, format: .colonSeparated)
				cell.depletionLabel.textColor = .red
			}
		}
	}
	
	override var hashValue: Int {
		return identifier.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCExtractorDetailsRow)?.hashValue == hashValue
	}

}
