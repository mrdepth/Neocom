//
//  DamageTypeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class DamageTypeCell: RowCell {
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var emLabel: DamageTypeLabel!
	@IBOutlet weak var thermalLabel: DamageTypeLabel!
	@IBOutlet weak var kineticLabel: DamageTypeLabel!
	@IBOutlet weak var explosiveLabel: DamageTypeLabel!
}

extension Prototype {
	enum DamageTypeCell {
		static let `default` = Prototype(nib: UINib(nibName: "DamageTypeCell", bundle: nil), reuseIdentifier: "DamageTypeCell")
		static let compact = Prototype(nib: UINib(nibName: "DamageTypeCompactCell", bundle: nil), reuseIdentifier: "DamageTypeCompactCell")
	}
}

extension Tree.Item {
	class DamageTypeRow: Row<Tree.Content.DamageType> {

		override func isEqual(_ other: Tree.Item.Base<Tree.Content.DamageType, TreeItemNull>) -> Bool {
			return self === other
		}
	}
}

extension Tree.Content {
	struct DamageType: Hashable {
		enum Unit: Hashable {
			case none
			case percent
		}
		var prototype: Prototype?
		var title: String?
		var unit: Unit
		var em: Double
		var thermal: Double
		var kinetic: Double
		var explosive: Double
		
		init(prototype: Prototype = Prototype.DamageTypeCell.default,
			 title: String? = nil,
			 unit: Unit = .none,
			 em: Double,
			 thermal: Double,
			 kinetic: Double,
			 explosive: Double) {
			self.prototype = prototype
			self.title = title
			self.unit = unit
			self.em = em
			self.thermal = thermal
			self.kinetic = kinetic
			self.explosive = explosive
		}
	}
}

extension Tree.Content.DamageType: CellConfigurable {
	func configure(cell: UITableViewCell, treeController: TreeController?) {
		guard let cell = cell as? DamageTypeCell else {return}
		cell.titleLabel?.text = title
		
		var total = em + thermal + kinetic + explosive
		if total == 0 {
			total = 1
		}
		
		cell.emLabel.progress = Float(em / total)
		cell.thermalLabel.progress = Float(thermal / total)
		cell.kineticLabel.progress = Float(kinetic / total)
		cell.explosiveLabel.progress = Float(explosive / total)
		if unit == .percent {
			cell.emLabel.text = "\(Int(em * 100))%"
			cell.thermalLabel.text = "\(Int(thermal * 100))%"
			cell.kineticLabel.text = "\(Int(kinetic * 100))%"
			cell.explosiveLabel.text = "\(Int(explosive * 100))%"
		}
		else {
			cell.emLabel.text = UnitFormatter.localizedString(from: em, unit: .none, style: .short)
			cell.thermalLabel.text = UnitFormatter.localizedString(from: thermal, unit: .none, style: .short)
			cell.kineticLabel.text = UnitFormatter.localizedString(from: kinetic, unit: .none, style: .short)
			cell.explosiveLabel.text = UnitFormatter.localizedString(from: explosive, unit: .none, style: .short)
		}

	}
}
