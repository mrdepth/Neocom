//
//  NCFacilityChartTableViewCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFacilityChartTableViewCell: NCTableViewCell {
	@IBOutlet weak var chartView: ChartView!
	@IBOutlet weak var xLabel: UILabel!
	@IBOutlet weak var yLabel: UILabel!
}

extension Prototype {
	enum NCFacilityChartTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCFacilityChartTableViewCell", bundle: nil), reuseIdentifier: "NCFacilityChartTableViewCell")
	}
}

class NCFacilityChartRow: TreeRow {
	let data: [BarChart.Item]
	let xRange: ClosedRange<Date>
	let yRange: ClosedRange<Double>
	let currentTime: Date
	let expiryTime: Date
	let identifier: Int64
	
	init(data: [BarChart.Item], xRange: ClosedRange<Date>, yRange: ClosedRange<Double>, currentTime: Date, expiryTime: Date, identifier: Int64) {
		self.data = data
		self.xRange = xRange
		self.yRange = yRange
		self.currentTime = currentTime
		self.expiryTime = expiryTime
		self.identifier = identifier
		super.init(prototype: Prototype.NCFacilityChartTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFacilityChartTableViewCell else {return}
		
		let chart = cell.chartView.charts.first as? BarChart ?? BarChart()
		let line = cell.chartView.charts.last as? LineChart ?? LineChart()
		
		chart.data = data
		chart.xRange = xRange.lowerBound.timeIntervalSinceReferenceDate...xRange.upperBound.timeIntervalSinceReferenceDate
		chart.yRange = yRange
		
		line.data = [(x: currentTime.timeIntervalSinceReferenceDate, y: 0), (x: currentTime.timeIntervalSinceReferenceDate, y: 1)]
		line.xRange = xRange.lowerBound.timeIntervalSinceReferenceDate...xRange.upperBound.timeIntervalSinceReferenceDate
		line.yRange = 0...1
		line.color = UIColor.white
		
		if cell.chartView.charts.isEmpty {
			cell.chartView.addChart(chart, animated: false)
			cell.chartView.addChart(line, animated: false)
		}
		
		let t = expiryTime.timeIntervalSince(currentTime)
		if t > 0 {
			cell.xLabel.text = NCTimeIntervalFormatter.localizedString(from: t, precision: .minutes)
		}
		else {
			cell.xLabel?.text = NSLocalizedString("Finished", comment: "")
		}
		cell.yLabel.text = NCUnitFormatter.localizedString(from: yRange.upperBound, unit: .none, style: .full)
	}
	
	override var hashValue: Int {
		return identifier.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCFacilityChartRow)?.hashValue == hashValue
	}

}
