//
//  ChartView.swift
//  Chart
//
//  Created by Artem Shimanski on 03.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

let Offset: CGFloat = 4
let ThinnestLineWidth = 1.0 / UIScreen.main.scale


extension ClosedRange where Bound == Double {
	func convert(_ x: Bound, to: ClosedRange<Bound>) -> Double {
		return (x - lowerBound) / (upperBound - lowerBound) * (to.upperBound - to.lowerBound) + to.lowerBound
	}
}


class Chart: Hashable {
	
	var hashValue: Int {
		return Unmanaged.passUnretained(self).toOpaque().hashValue
	}
	
	public static func ==(lhs: Chart, rhs: Chart) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
	
	fileprivate weak var chartView: ChartView!
	func present(animated: Bool) {}
	func dismiss(animated: Bool) {}
	func update(animated: Bool) {}
}

class LineChart: Chart {
	private(set) var data: [(x: Double, y: Double)] = []
	
	var xRange: ClosedRange<Double> = 0...0 {
		didSet {
			update(animated: true)
		}
	}
	
	var yRange: ClosedRange<Double> = 0...0 {
		didSet {
			update(animated: true)
		}
	}
	
	var color: UIColor = .lightGray {
		didSet {
			layer.strokeColor = color.cgColor
		}
	}

	private lazy var layer: CAShapeLayer = {
		let layer = CAShapeLayer()
		layer.fillColor = nil
		layer.strokeColor = self.color.cgColor
		layer.transform = CATransform3DMakeAffineTransform(CGAffineTransform.init(scaleX: 1, y: -1))
		return layer
	}()
	
	func setData(_ data: [(x: Double, y: Double)], animated: Bool) {
		self.data = data
		update(animated: animated)
	}
	
	override func present(animated: Bool) {
		chartView.plot.layer.addSublayer(layer)
		layer.frame = chartView.plot.bounds
		let p = path()
		
		layer.path = p.cgPath
		
		if animated {
			var transform = CGAffineTransform.identity
			transform = transform.translatedBy(x: 0, y: layer.frame.size.height)
			transform = transform.scaledBy(x: 1.0, y: 0.0)
			p.apply(transform)
			
			let animation = CABasicAnimation(keyPath: "path")
			animation.fromValue = p.cgPath
			animation.duration = 0.25
			layer.add(animation, forKey: nil)
		}
	}
	
	override func dismiss(animated: Bool) {
	}
	
	private var updateWork: DispatchWorkItem?
	
	override func update(animated: Bool) {
		guard chartView != nil else {return}
		
		updateWork?.cancel()
		
		updateWork = DispatchWorkItem { [weak self] in
			guard let strongSelf = self else {return}
			let from = strongSelf.layer.path
			strongSelf.layer.path = strongSelf.path().cgPath
			if animated {
				let animation = CABasicAnimation(keyPath: "path")
				animation.fromValue = from
				animation.duration = 0.25
				strongSelf.layer.add(animation, forKey: nil)
			}
			strongSelf.updateWork = nil
		}
		DispatchQueue.main.async(execute: updateWork!)
	}
	
	private func path() -> UIBezierPath {
		let path = UIBezierPath()
		var isStart = true
		for p in data {
			if isStart {
				path.move(to: CGPoint(x: p.x, y: p.y))
				isStart = false
			}
			else {
				path.addLine(to: CGPoint(x: p.x, y: p.y))
			}
		}
		
		let size = layer.frame.size
		var transform = CGAffineTransform.identity
		let w = xRange.upperBound - xRange.lowerBound
		if w > 0 {
			transform = transform.scaledBy(x: size.width / CGFloat(w), y: size.height / CGFloat(yRange.upperBound - yRange.lowerBound))
			transform = transform.translatedBy(x: -CGFloat(xRange.lowerBound), y: -CGFloat(yRange.lowerBound))
			path.apply(transform)
		}
		
		return path
	}

}

class ChartAxis {
	enum Location {
		case top
		case bottom
		case left
		case right
	}
	
	var textAttributes: [String: Any] = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: .footnote)]
	var range: ClosedRange<Double> = 0...1
	func title(for x: Double) -> String {
		return String(format: "%.1f", x)
	}
}

class ChartView: UIView {
	
	var axes: [ChartAxis.Location: ChartAxis] = [:] {
		didSet {
			var l: Set<ChartAxis.Location> = [.left, .right, .bottom, .top]
			for (location, _) in axes {
				l.remove(location)
				if axesViews[location] == nil {
					let stackView = UIStackView()
					stackView.translatesAutoresizingMaskIntoConstraints = true
					switch location {
					case .left:
						stackView.axis = .vertical
						stackView.alignment = .trailing
					case .right:
						stackView.axis = .vertical
						stackView.alignment = .leading
					case .top:
						stackView.axis = .horizontal
						stackView.alignment = .bottom
					case .bottom:
						stackView.axis = .horizontal
						stackView.alignment = .top
					}
					stackView.distribution = .fillEqually
					addSubview(stackView)
					axesViews[location] = stackView
				}
			}
			for location in l {
				guard let stackView = axesViews[location] else {continue}
				stackView.removeFromSuperview()
			}
			needsUpdateTitles = true
			setNeedsLayout()
		}
	}

	private(set) lazy var plot: UIView = {
		let plot = UIView(frame: self.bounds)
		plot.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(plot)
		plot.backgroundColor = self.tintColor.withAlphaComponent(0.15)
		return plot
	}()

	private(set) var charts: [Chart] = []
	

	override func layoutSubviews() {
		if needsUpdateTitles {
			updateTitles()
		}
		
		super.layoutSubviews()
		
		var plotFrameInsets = UIEdgeInsets.zero
		for (location, stackView) in axesViews {
			let size = stackView.bounds.size
			
			switch location {
			case .left:
				plotFrameInsets.left = (size.width + Offset).rounded(.up)
			case .right:
				plotFrameInsets.right = (size.width + Offset).rounded(.up)
			case .top:
				plotFrameInsets.top = size.height.rounded(.up)
			case .bottom:
				plotFrameInsets.bottom = size.height.rounded(.up)
			}
		}
		let plotFrame = UIEdgeInsetsInsetRect(bounds, plotFrameInsets)
		
		if grid.frame != plotFrame || grid.path == nil {
			grid.frame = plotFrame
			let w = plotFrame.width / (plotFrame.width / 24).rounded(.down)
			let h = plotFrame.height / (plotFrame.height / 24).rounded(.down)
			let path = UIBezierPath()
			var p = CGPoint.zero
			while p.x <= plotFrame.size.width {
				path.move(to: CGPoint(x: p.x, y: 0))
				path.addLine(to: CGPoint(x: p.x, y: plotFrame.height))
				p.x += w
			}
			while p.y <= plotFrame.size.height {
				path.move(to: CGPoint(x: 0, y: p.y))
				path.addLine(to: CGPoint(x: plotFrame.width, y: p.y))
				p.y += h
			}
			grid.path = path.cgPath
		}
		
		for (location, stackView) in axesViews {
			switch location {
			case .left:
				stackView.frame = CGRect(x: 0, y: plotFrame.minY, width: stackView.bounds.size.width, height: plotFrame.size.height)
			case .right:
				stackView.frame = CGRect(x: plotFrame.maxX + Offset, y: plotFrame.minY, width: stackView.bounds.size.width, height: plotFrame.size.height)
			case .top:
				stackView.frame = CGRect(x: plotFrame.minX, y: 0, width: plotFrame.size.width, height: stackView.bounds.size.height)
			case .bottom:
				stackView.frame = CGRect(x: plotFrame.minX, y: plotFrame.maxY, width: plotFrame.size.width, height: stackView.bounds.size.height)
			}
			
		}
		
		plot.frame = plotFrame
	}
	
	func addChart(_ chart: Chart, animated: Bool) {
		layoutIfNeeded()
		charts.append(chart)
		chart.chartView = self
		chart.present(animated: animated)
	}
	
	func removeChart(_ chart: Chart, animated: Bool) {
		if let i = charts.index(of: chart) {
			chart.dismiss(animated: animated)
			charts.remove(at: i)
			chart.chartView = nil
		}
	}
	
	private var axesViews: [ChartAxis.Location: UIStackView] = [:]
	private var needsUpdateTitles: Bool = true

	private lazy var grid: CAShapeLayer = {
		let grid = CAShapeLayer()
		grid.fillColor = nil
		grid.strokeColor = self.tintColor.withAlphaComponent(0.5).cgColor
		grid.lineWidth = ThinnestLineWidth
		self.layer.insertSublayer(grid, above: self.plot.layer)
		return grid
	}()
	
	private func updateTitles() {
		var plotFrameInsets = UIEdgeInsets.zero
		var sizes: [ChartAxis.Location: CGSize] = [:]
		
		for (location, axis) in axes {
			let s = NSAttributedString(string: axis.title(for: axis.range.upperBound), attributes: axis.textAttributes)
			let size = s.boundingRect(with: bounds.size, options: [.usesLineFragmentOrigin], context: nil).size
			sizes[location] = size
			
			switch location {
			case .left:
				plotFrameInsets.left = (size.width + Offset).rounded(.up)
			case .right:
				plotFrameInsets.right = (size.width + Offset).rounded(.up)
			case .top:
				plotFrameInsets.top = size.height.rounded(.up)
			case .bottom:
				plotFrameInsets.bottom = size.height.rounded(.up)
			}
		}
		
		let plotFrame = UIEdgeInsetsInsetRect(bounds, plotFrameInsets)
		
		for (location, axis) in axes {
			
			let n: Int
			switch location {
			case .left, .right:
				n = Int(trunc(plotFrame.size.height / (sizes[location]!.height + 4)))
			case .top, .bottom:
				n = Int(trunc(plotFrame.size.width / (sizes[location]!.width + 8)))
			}
			
			var size = CGSize.zero
			let stackView = axesViews[location]!
			var labels = stackView.arrangedSubviews as! [UILabel]
			for i in 0..<n {
				let x = (0...Double(n - 1)).convert(Double( stackView.axis == .horizontal ? i : (n - i - 1)), to: axis.range)
				let s = NSAttributedString(string: axis.title(for: x), attributes: axis.textAttributes)
				let label = !labels.isEmpty ? labels.removeFirst() : {
					let label = UILabel(frame: .zero)
					label.textColor = tintColor
					label.translatesAutoresizingMaskIntoConstraints = false
					label.textAlignment = .center
					stackView.addArrangedSubview(label)
					return label
				}()
				label.attributedText = s
				label.sizeToFit()
				if stackView.axis == .horizontal {
					size.width += label.bounds.size.width
					size.height = max(size.height, label.bounds.size.height)
				}
				else {
					size.height += label.bounds.size.height
					size.width = max(size.width, label.bounds.size.width)
				}
			}
			labels.forEach {$0.removeFromSuperview()}
			stackView.bounds.size = size
		}
	}
}
