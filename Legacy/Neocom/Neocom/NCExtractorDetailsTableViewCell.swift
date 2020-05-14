//
//  NCExtractorDetailsTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import Dgmpp

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
	let currentTime: Date
	let yield: Int
	let waste: Int
	let currentState: DGMProductionState?
	let wasteState: DGMProductionState?
	let extractor: DGMExtractorControlUnit
	let identifier: Int64

	init(extractor: DGMExtractorControlUnit, currentTime: Date) {
		self.extractor = extractor
		self.currentTime = currentTime
		identifier = extractor.identifier
		let states = extractor.states.filter{$0.cycle != nil}
		
		
		(yield, waste) = extractor.cycles.reduce((0,0)) {
			($0.0 + $1.yield.quantity, $0.1 + $1.waste.quantity)
		}
		
		currentState = states.first {($0.timestamp...($0.timestamp + $0.cycle!.duration)).contains(currentTime)}
		wasteState = states.first {$0.timestamp > currentTime && $0.cycle!.waste.quantity > 0}
		
		super.init(prototype: Prototype.NCExtractorDetailsTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCExtractorDetailsTableViewCell else {return}
		let sum = yield + waste
		
		let extractor = self.extractor
		let currentTime = self.currentTime
		let currentState = self.currentState
		cell.sumLabel.text = NCUnitFormatter.localizedString(from: sum, unit: .none, style: .full)
		let duration = extractor.expiryTime.timeIntervalSince(extractor.installTime)
		//			let duration = extractor.expiryTime - extractor.installTime
		
		cell.yieldLabel.text = duration > 0 ? NCUnitFormatter.localizedString(from: Double(sum) / (duration / 3600), unit: .none, style: .full) : "0"
		
		
		let remains = extractor.expiryTime.timeIntervalSince(currentTime)
		cell.cycleTimeLabel.text = NCTimeIntervalFormatter.localizedString(from: currentState?.cycle?.duration ?? 0, precision: .hours, format: .colonSeparated)
		
		if let currentState = currentState, let cycle = currentState.cycle, remains > 0 {
			let t = currentTime.clamped(to: cycle.start...cycle.end).timeIntervalSince(cycle.start)
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
	
	override var hash: Int {
		return identifier.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCExtractorDetailsRow)?.hashValue == hashValue
	}

}
