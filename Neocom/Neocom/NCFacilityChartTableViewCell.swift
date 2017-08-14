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
}

extension Prototype {
	enum NCFacilityChartTableViewCell {
		static let `default` = Prototype(nib: UINib(nibName: "NCFacilityChartTableViewCell", bundle: nil), reuseIdentifier: "NCFacilityChartTableViewCell")
	}
}

class NCFacilityChartRow: TreeRow {
	let data: [BarChart.Item]
	let xRange: ClosedRange<Double>
	let yRange: ClosedRange<Double>
	let currentTime: TimeInterval
	init(data: [BarChart.Item], xRange: ClosedRange<Double>, yRange: ClosedRange<Double>, currentTime: TimeInterval) {
		self.data = data
		self.xRange = xRange
		self.yRange = yRange
		self.currentTime = currentTime
		super.init(prototype: Prototype.NCFacilityChartTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFacilityChartTableViewCell else {return}
		
		let chart = cell.chartView.charts.first as? BarChart ?? BarChart()
		let line = cell.chartView.charts.last as? LineChart ?? LineChart()

		chart.data = data
		chart.xRange = xRange
		chart.yRange = yRange
		
		line.data = [(x: currentTime, y: 0), (x: currentTime, y: 1)]
		line.xRange = xRange
		line.yRange = 0...1
		line.color = UIColor.caption
		
		if cell.chartView.charts.isEmpty {
			cell.chartView.addChart(chart, animated: true)
			cell.chartView.addChart(line, animated: true)
		}

	}
}
