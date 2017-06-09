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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        separatorInset = .zero
    }
}

extension Prototype {
	enum NCPieChartTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCPieChartTableViewCell", bundle: nil), reuseIdentifier: "NCPieChartTableViewCell")
	}
}

class NCPieChartRow: TreeRow {
	
	private(set) var segments: [PieSegment] = []
	let formatter: Formatter?
	
	init(formatter: Formatter?) {
		self.formatter = formatter
		super.init(prototype: Prototype.NCPieChartTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCPieChartTableViewCell else {return}
		cell.pieChartView.formatter = formatter
		cell.pieChartView.removeAllSegments()
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		segments.forEach {cell.pieChartView.add(segment: $0)}
		CATransaction.commit()
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
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCPieChartRow)?.hashValue == hashValue
	}
	
	override var hashValue: Int {
		return Unmanaged.passUnretained(self).toOpaque().hashValue
	}
	
	override func transitionStyle(from node: TreeNode) -> TransitionStyle {
		return .none
	}

}
