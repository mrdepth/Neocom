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

class ChartShapeLayer: CAShapeLayer {
	override func action(forKey event: String) -> CAAction? {
		if event == "path" {
			return CABasicAnimation(keyPath: "path")
		}
		else {
			return super.action(forKey: event)
		}
	}
}

extension CGSize {
	func union(_ other: CGSize) -> CGSize {
		return CGSize(width: max(width, other.width), height: max(height, other.height))
	}
}


extension ClosedRange where Bound == Double {
	func convert(_ x: Bound, to: ClosedRange<Bound>) -> Double {
		return (x - lowerBound) / (upperBound - lowerBound) * (to.upperBound - to.lowerBound) + to.lowerBound
	}
}

class AnimationDelegate: NSObject, CAAnimationDelegate {
	var didStopHandler: ((CAAnimation, Bool) -> Void)?
	public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		didStopHandler?(anim ,flag)
	}
}

class Chart: Hashable {
	
	var hashValue: Int {
		return Unmanaged.passUnretained(self).toOpaque().hashValue
	}
	
	public static func ==(lhs: Chart, rhs: Chart) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
	
	var needsUpdate: Bool = false {
		didSet {
			if needsUpdate {
				chartView?.setNeedsLayout()
			}
		}
	}
	
	fileprivate weak var chartView: ChartView?
	func present() {}
	func dismiss() {}
	func update() {}
}

class ChartAxis {
	enum Location {
		case top
		case bottom
		case left
		case right
	}
	
	var textAttributes: [String: Any] = [NSFontAttributeName: UIFont.preferredFont(forTextStyle: .footnote)]
	
	var range: ClosedRange<Double> = 0...0 {
		didSet {
			chartView?.needsUpdateTitles = true
			chartView?.setNeedsLayout()
		}
	}
	
	func title(for x: Double) -> String {
		return String(format: "%.1f", x)
	}
	
	fileprivate weak var chartView: ChartView?
}

class ChartView: UIView {
	
	var axes: [ChartAxis.Location: ChartAxis] = [:] {
		didSet {
			var l: Set<ChartAxis.Location> = [.left, .right, .bottom, .top]
			for (location, axis) in axes {
				axis.chartView = self
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

	private(set) lazy var plot: CALayer = {
		let plot = CALayer()
		plot.frame = self.bounds
		self.layer.addSublayer(plot)
//		plot.backgroundColor = self.tintColor.withAlphaComponent(0.15).cgColor
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
		
		guard plotFrame.width > 0 && plotFrame.height > 0 else {return}
		
		if grid.path == nil {
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
		else if grid.frame != plotFrame {
			let from = grid.path!
			let to = UIBezierPath(cgPath: from)
			var transform = CGAffineTransform.identity
			transform = transform.scaledBy(x: plotFrame.width / grid.frame.size.width, y: plotFrame.height / grid.frame.size.height)
			to.apply(transform)
			
			grid.frame = plotFrame
			grid.path = to.cgPath
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
		let isChanged = plot.frame == plotFrame
		plot.frame = plotFrame
		for chart in charts {
			if isChanged || chart.needsUpdate {
				chart.update()
			}
		}
		
	}
	
	func addChart(_ chart: Chart, animated: Bool) {
		layoutIfNeeded()
		charts.append(chart)
		chart.chartView = self
		chart.present()
	}
	
	func removeChart(_ chart: Chart, animated: Bool) {
		if let i = charts.index(of: chart) {
			chart.dismiss()
			charts.remove(at: i)
			chart.chartView = nil
		}
	}
	
	private var axesViews: [ChartAxis.Location: UIStackView] = [:]
	fileprivate var needsUpdateTitles: Bool = true

	private lazy var grid: CAShapeLayer = {
		let grid = ChartShapeLayer()
		grid.fillColor = nil
		grid.strokeColor = self.tintColor.withAlphaComponent(0.5).cgColor
		grid.lineWidth = ThinnestLineWidth
		
		grid.backgroundColor = self.tintColor.withAlphaComponent(0.15).cgColor
		self.layer.insertSublayer(grid, below: self.plot)
		return grid
	}()
	
	private func updateTitles() {
		var plotFrameInsets = UIEdgeInsets.zero
		var sizes: [ChartAxis.Location: CGSize] = [:]
		
		var titles: [ChartAxis.Location:[NSAttributedString]] = [:]
		
		var plotFrame = bounds
		
		for _ in 0..<10 {
			
			for (location, axis) in axes {
				
				let n: Int
				if let size = sizes[location] {
					switch location {
					case .left, .right:
						n = Int(trunc(plotFrame.size.height / (size.height + 4)))
					case .top, .bottom:
						n = Int(trunc(plotFrame.size.width / (size.width + 8)))
					}
				}
				else {
					n = 1
				}
				
				var array = [NSAttributedString]()
				for i in 0..<n {
					let x: Double
					switch location {
					case .bottom, .top:
						x = (0...Double(n - 1)).convert(Double(i), to: axis.range)
					case .left, .right:
						x = (0...Double(n - 1)).convert(Double(n - i - 1), to: axis.range)
					}
					let s = NSAttributedString(string: axis.title(for: x), attributes: axis.textAttributes)
					array.append(s)
					let size = s.boundingRect(with: bounds.size, options: [.usesLineFragmentOrigin], context: nil).size
					sizes[location] = size.union(sizes[location] ?? .zero)
				}
				titles[location] = array
			}
			var plotFrameInsets = UIEdgeInsets.zero

			for (location, size) in sizes {
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
			
			let other = UIEdgeInsetsInsetRect(bounds, plotFrameInsets)

			defer {
				plotFrame = other
			}
			if other == plotFrame {
				break
			}
		}
		
		for (location, titles) in titles {
			var size = CGSize.zero
			let stackView = axesViews[location]!
			var labels = stackView.arrangedSubviews as! [UILabel]
			
			for title in titles {
				let label = !labels.isEmpty ? labels.removeFirst() : {
					let label = UILabel(frame: .zero)
					label.textColor = tintColor
					label.translatesAutoresizingMaskIntoConstraints = false
					label.textAlignment = .center
					stackView.addArrangedSubview(label)
					return label
					}()
				label.attributedText = title
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


class LineChart: Chart {
	var data: [(x: Double, y: Double)] = [] {
		didSet {
			needsUpdate = true
		}
	}
	
	var xRange: ClosedRange<Double> = 0...0 {
		didSet {
			needsUpdate = true
		}
	}
	
	var yRange: ClosedRange<Double> = 0...0 {
		didSet {
			needsUpdate = true
		}
	}
	
	var color: UIColor = .lightGray {
		didSet {
			layer.strokeColor = color.cgColor
		}
	}
	
	private lazy var layer: CAShapeLayer = {
		let layer = ChartShapeLayer()
		layer.fillColor = nil
		layer.strokeColor = self.color.cgColor
		layer.transform = CATransform3DMakeAffineTransform(CGAffineTransform.init(scaleX: 1, y: -1))
		return layer
	}()
	
	override func present() {
		guard let chartView = chartView else {return}
		chartView.plot.addSublayer(layer)
		layer.frame = chartView.plot.bounds
		let p = path()
		
		layer.path = p.cgPath
		
		var transform = CGAffineTransform.identity
		transform = transform.scaledBy(x: 1.0, y: 0.0)
		p.apply(transform)
		
		let animation = CABasicAnimation(keyPath: "path")
		animation.fromValue = p.cgPath
		animation.duration = 0.25
		layer.add(animation, forKey: nil)
	}
	
	override func dismiss() {
		let layer = self.layer
		
		guard let from = layer.path else {
			layer.removeFromSuperlayer()
			return
		}
		let to = UIBezierPath(cgPath: from)
		var transform = CGAffineTransform.identity
		transform = transform.scaledBy(x: 1.0, y: 0.0)
		to.apply(transform)
		
		CATransaction.begin()
		layer.path = to.cgPath
		CATransaction.setCompletionBlock({
			layer.removeFromSuperlayer()
		})
		CATransaction.commit()
	}
	
	
	override func update() {
		guard let chartView = chartView else {return}
		layer.frame = chartView.plot.bounds
		layer.path = path().cgPath
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

class BarChart: Chart {
	class Layer: CALayer {
		
		weak var barChart: BarChart?
		
//		var data: [Item]? {
//			didSet {
//				setNeedsDisplay()
//			}
//		}
		
		
		override func draw(in ctx: CGContext) {
			guard let barChart = self.barChart else {return}
//			guard let data = data else {return}
			let data = barChart.data
			guard !data.isEmpty else {return}
			
			let size = bounds.size
			let xRange = barChart.xRange
			let yRange = barChart.yRange
			
			let color0 = UIColor.green.cgColor
			let color1 = UIColor.red.cgColor
			
			let r = CGSize(width: CGFloat(xRange.upperBound - xRange.lowerBound), height: CGFloat(yRange.upperBound - yRange.lowerBound))
			guard r.width > 0, r.height > 0 else {return}

			ctx.saveGState()
			ctx.setShouldAntialias(false)
			
			ctx.scaleBy(x: size.width / r.width, y: size.height / r.height)
			ctx.translateBy(x: -CGFloat(xRange.lowerBound), y: -CGFloat(yRange.lowerBound))
			
			let minW = 4.0 / Double(size.width / r.width)
			let inset = 1.0 / (size.width / r.width)

			
			var start = data[0]
			var y: (Double, Double) = (0,0)
			var w: Double = 0
			
			var prev = start
			for i in data[1..<data.count] {
				let dw = i.x - prev.x
				prev = i
				w += dw
				y.0 += i.y * i.f * dw
				y.1 += i.y * (1 - i.f) * dw
				if w >= minW {
					y.0 /= w
					y.1 /= w
					
					if y.1 > 0 {
						ctx.setFillColor(color1)
						ctx.fill(CGRect(x: start.x, y: 0, width: w, height: y.1).insetBy(dx: inset, dy: 0))
					}
					if y.0 > 0 {
						ctx.setFillColor(color0)
						ctx.fill(CGRect(x: start.x, y: y.1, width: w, height: y.0).insetBy(dx: inset, dy: 0))
					}
					
					start = i
					w = 0
					y = (0, 0)
				}
			}
			
			ctx.restoreGState()
			
		}
	}
	
	struct Item {
		var x: Double
		var y: Double
		var f: Double
	}
	
	var data: [Item] = [] {
		didSet {
			needsUpdate = true
		}
	}
	
	var xRange: ClosedRange<Double> = 0...0 {
		didSet {
			needsUpdate = true
		}
	}
	
	var yRange: ClosedRange<Double> = 0...0 {
		didSet {
			needsUpdate = true
		}
	}
	
	var color: UIColor = .lightGray {
		didSet {
		}
	}
	
	private lazy var contentLayer: Layer = {
		let layer = Layer()
		layer.barChart = self
		layer.needsDisplayOnBoundsChange = true
		layer.transform = CATransform3DMakeAffineTransform(CGAffineTransform.init(scaleX: 1, y: -1))
		return layer
	}()
	
	private lazy var layer: CALayer = {
		let layer = CALayer()
		layer.needsDisplayOnBoundsChange = true
		layer.anchorPoint = CGPoint(x: 0.5, y: 1)
		layer.addSublayer(self.contentLayer)
		return layer
	}()
	
	override func present() {
		guard let chartView = chartView else {return}
		chartView.plot.addSublayer(layer)
		layer.frame = chartView.plot.bounds
		contentLayer.frame = layer.bounds
		
		let animation = CABasicAnimation(keyPath: "transform")
		animation.fromValue = CATransform3DMakeAffineTransform(CGAffineTransform(scaleX: 1, y: 0))
		animation.duration = 0.25
		layer.add(animation, forKey: "transform")

	}
	
	override func dismiss() {
		let layer = self.layer
		layer.removeFromSuperlayer()
		
		
//		CATransaction.begin()
//		CATransaction.setCompletionBlock({
//		})
//		CATransaction.commit()
	}
	
	
	override func update() {
		guard let chartView = chartView else {return}
		layer.frame = chartView.plot.bounds
		contentLayer.frame = layer.bounds
//		contentLayer.data = data
		contentLayer.setNeedsDisplay()
	}
	
}
