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
	@IBOutlet weak var optimalLabel: UILabel!
	@IBOutlet weak var falloffLabel: UILabel!
	@IBOutlet weak var rawDpsLabel: UILabel!
	@IBOutlet weak var dpsLabel: UILabel!
	@IBOutlet weak var dpsAccuracyView: UIView!
	@IBOutlet weak var stepper: UIStepper!

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
		cell.damageChartView.module = module
		cell.damageChartView.charges = charges
		let targetSignature = Double(hullType?.signature ?? 0)
		
		cell.damageChartView.targetSignature = targetSignature
	}
}

