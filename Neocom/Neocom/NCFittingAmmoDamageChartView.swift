//
//  NCFittingAmmoDamageChartView.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit


class NCFittingAmmoDamageChartView: UIView {
	private var layers: [(UIBezierPath, CAShapeLayer)] = []
	private var chartSize: CGSize = .zero
	
	override func layoutSubviews() {
		super.layoutSubviews()
		var transform = CGAffineTransform(scaleX: CGFloat(1.0 / chartSize.width) * bounds.size.width, y: -CGFloat(1.0 / chartSize.height) * bounds.size.height)
		transform = transform.translatedBy(x: 0, y: CGFloat(-chartSize.height))
		
		for (path, layer) in layers {
			let path = path.copy() as! UIBezierPath
			path.apply(transform)
			layer.frame = bounds
			layer.path = path.cgPath
		}
	}
	
	func add(chart: UIBezierPath) {
		let n = layers.count
		let s = CGFloat(n / 15) / 15.0
		let h = CGFloat(n % 15) / 15.0
		let color = UIColor(hue: s, saturation: h, brightness: 1, alpha: 1.0)
		
		let shapeLayer = CAShapeLayer()
		shapeLayer.fillColor = nil
		shapeLayer.strokeColor = color.cgColor
		layer.addSublayer(shapeLayer)
		layers.append((chart, shapeLayer))
		
		var size: CGSize = .zero
		for (chart, _) in layers {
			let b = chart.bounds
			size.width = max(size.width, b.width)
			size.height = max(size.height, b.height)
		}
		chartSize = size
		
		setNeedsLayout()
	}
	
	func removeChart(at index: Int) {
		layers[index].1.removeFromSuperlayer()
		layers.remove(at: index)
		setNeedsLayout()
	}
	
	var numberOfCharts: Int {
		return layers.count
	}
}
