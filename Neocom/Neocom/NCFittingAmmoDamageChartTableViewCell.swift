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
		cell.damageChartView.module = module
		cell.damageChartView.charges = charges
		let targetSignature = Double(hullType?.signature ?? 0)
		
		cell.damageChartView.targetSignature = targetSignature
		
		cell.chargesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
		
		guard let invTyps = NCDatabase.sharedDatabase?.invTypes else {return}
		for chargeID in charges {
			guard let text = invTyps[chargeID]?.typeName else {continue}
			let label = UILabel(frame: .zero)
			label.font = UIFont.preferredFont(forTextStyle: .footnote)
			label.textColor = cell.damageChartView.color(for: chargeID) ?? .white
			
//			let w = label.font.lineHeight
//			let image = UIImage.image(color: label.textColor, size: CGSize(width: w, height: w), scale: 1)
//			label.attributedText = NSAttributedString(image: image, font: label.font)  + text
			label.text = text
			
			cell.chargesStackView.addArrangedSubview(label)
		}
		
	}
}

