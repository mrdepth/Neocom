//
//  NCFittingAmmoDamageChartTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingAmmoDamageChartTableViewCell: NCTableViewCell {
	@IBOutlet weak var damageChartView: NCFittingAmmoDamageChartView!
	@IBOutlet weak var fullRangeLabel: UILabel!
	@IBOutlet weak var halfRangeLabel: UILabel!
	@IBOutlet weak var dpsLabel: UILabel!
	@IBOutlet weak var hullLabel: UILabel!
	@IBOutlet weak var stepper: UIStepper!
	@IBOutlet weak var chargesStackView: UIStackView!

}

extension Prototype {
	struct NCFittingAmmoDamageChartTableViewCell {
		static let `default` = Prototype(nib: nil, reuseIdentifier: "NCFittingAmmoDamageChartTableViewCell")
	}
}

class NCFittingAmmoDamageChartRow: TreeRow {
	let module: NCFittingModule

	var charges: [Int] = []
	
	let ship: NCFittingShip?
	let count: Int

	lazy var hullType: NCDBDgmppHullType? = {
		guard let ship = self.ship else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[ship.typeID]?.hullType
	}()

	init(module: NCFittingModule, count: Int) {
		self.module = module
		self.ship = module.owner as? NCFittingShip
		self.count = count
		super.init(prototype: Prototype.NCFittingAmmoDamageChartTableViewCell.default)
	}
	
	override var hashValue: Int {
		return module.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFittingAmmoDamageChartRow)?.hashValue == hashValue
	}

	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingAmmoDamageChartTableViewCell else {return}
		let module = self.module

		cell.damageChartView.module = module
		cell.damageChartView.charges = charges
		let targetSignature = Double(hullType?.signature ?? 0)
		
		cell.damageChartView.targetSignature = targetSignature
		
		cell.chargesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

		guard let invTyps = NCDatabase.sharedDatabase?.invTypes else {return}

		var typeNames = [Int: String]()
		var labels = [Int: UILabel]()
		for chargeID in self.charges {
			guard let typeName = invTyps[chargeID]?.typeName else {continue}
			typeNames[chargeID] = typeName
			
			let label = UILabel(frame: .zero)
			label.font = UIFont.preferredFont(forTextStyle: .footnote)
			label.textColor = cell.damageChartView.color(for: chargeID) ?? .white
			
			label.text = typeName
			cell.chargesStackView.addArrangedSubview(label)
			labels[chargeID] = label
		}
		
		let count = Double(self.count)
		cell.damageChartView.updateHandler = { updates in
			for (chargeID, label) in labels {
				guard let update = updates[chargeID],
					let typeName = typeNames[chargeID] else {continue}
				
				let dps = NCUnitFormatter.localizedString(from: update.dps * count, unit: .none, style: .full)
				let range = NCUnitFormatter.localizedString(from: update.range, unit: .meter, style: .full)
				label.text = "\(typeName) (\(dps) \(NSLocalizedString("at", comment: "DPS at range")) \(range))"
			}
			guard let maxDPS = updates.map({$0.value.dps}).max() else {return}
			guard let maxRange = updates.map({$0.value.range}).max() else {return}
			//cell.dpsLabel.text = NCUnitFormatter.localizedString(from: maxDPS, unit: .none, style: .full)
			cell.fullRangeLabel.text = NCUnitFormatter.localizedString(from: maxRange, unit: .meter, style: .full)
			cell.halfRangeLabel.text = NCUnitFormatter.localizedString(from: maxRange / 2, unit: .meter, style: .full)
		}
	}
}

