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
	
	init(sum: Int, yield: Int, cycleTime: TimeInterval, startTime: TimeInterval, currentTime: TimeInterval) {
		self.currentTime = currentTime
		super.init(prototype: Prototype.NCFacilityChartTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFacilityChartTableViewCell else {return}
	}
}
