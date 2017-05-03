//
//  NCPieChartTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCPieChartTableViewCell: NCTableViewCell {
	@IBOutlet var pieChartView: PieChartView!
}

extension Prototype {
	enum NCPieChartTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCPieChartTableViewCell", bundle: nil), reuseIdentifier: "NCPieChartTableViewCell")
	}
}

class NCPieChartRow: TreeRow {
	
	private(set) var segments: [PieSegment] = []
	
	init() {
		super.init(prototype: Prototype.NCPieChartTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCPieChartTableViewCell else {return}
		cell.pieChartView.removeAllSegments()
		segments.forEach {cell.pieChartView.add(segment: $0)}
	}
	
	func add(segment: PieSegment) {
		segments.append(segment)
		(treeController?.cell(for: self) as? NCPieChartTableViewCell)?.pieChartView.add(segment: segment)
	}
	
	func remove(segment: PieSegment) {
		if let i = segments.index(where: {$0 === segment}) {
			segments.remove(at: i)
		}
		(treeController?.cell(for: self) as? NCPieChartTableViewCell)?.pieChartView.remove(segment: segment)
	}

}
