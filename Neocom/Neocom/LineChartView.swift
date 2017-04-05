//
//  LineChartView.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

/*class LineChart: Hashable {

	var path: UIBezierPath
	var color: UIColor
	let identifier: Int?
	
	init(path: UIBezierPath, color: UIColor, identifier: Int? = nil) {
		self.path = path
		self.color = color
		self.identifier = identifier
	}
	
	var hashValue: Int {
		return identifier?.hashValue ?? color.hashValue
	}
	
	static func ==(lhs: LineChart, rhs: LineChart) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
}

struct Axis {
	var range: ClosedRange<Double>
	var formatter: Formatter?
}

class LineChartView: UIView {
	
	var charts: [LineChart] = [] {
		didSet {
			rebuild()
		}
	}
	
	var xAxis: Axis?
	var yAxis: Axis?
	var grid = CGSize(width: 24, height: 24)
	
	lazy var textAttributes: [String: Any] = {
		return [NSForegroundColorAttributeName: self.tintColor, NSFontAttributeName: UIFont.preferredFont(forTextStyle: .footnote)]
	}()
	
	override var bounds: CGRect {
		didSet {
			rebuild()
		}
	}
	
	private var _needsUpdateConstraints = true
	override func updateConstraints() {
		super.updateConstraints()
		if _needsUpdateConstraints {
			contentView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
			contentView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
			
			let views = ["xAxisView": xAxisView, "yAxisView": yAxisView, "canvasView": canvasView, "zeroPointLabel": zeroPointLabel]
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[yAxisView]-0-[canvasView(==320)]-(>=0)-|", options: [], metrics: nil, views: views))
			//			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[zeroPointLabel]-0-[canvasView]", options: [], metrics: nil, views: views))
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[zeroPointLabel]", options: [], metrics: nil, views: views))
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=0)-[canvasView(==128)]-0-[zeroPointLabel]-0-|", options: [], metrics: nil, views: views))
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0@240)-[yAxisView]-0-[zeroPointLabel]", options: [], metrics: nil, views: views))
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:[canvasView]-0-[xAxisView]", options: [], metrics: nil, views: views))
			//			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:[zeroPointLabel]-0-[xAxisView]", options: [], metrics: nil, views: views))
			xAxisView.leadingAnchor.constraint(equalTo: canvasView.leadingAnchor).isActive = true
			zeroPointLabel.trailingAnchor.constraint(equalTo: yAxisView.trailingAnchor).isActive = true
			_needsUpdateConstraints = false
		}
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		contentView.layoutIfNeeded()
		xAxisView.layoutIfNeeded()
		yAxisView.layoutIfNeeded()
		canvasView.layoutIfNeeded()
		
		var prev: UIView = zeroPointLabel
		
		for view in xAxisView.subviews {
			let a = prev.convert(prev.bounds, to: self).insetBy(dx: -4, dy: -4)
			let b = view.convert(view.bounds, to: self).insetBy(dx: -4, dy: -4)
			if a.intersects(b) || b.maxX > bounds.maxX || b.minY < 0 {
				view.isHidden = true
			}
			else {
				view.isHidden = false
				prev = view
			}
		}
		
		let canvas = canvasView.bounds
		for layer in chartLayers {
			layer.layer.frame = canvas
		}
		
		let path = UIBezierPath(rect: canvas)
		var p = CGPoint(x: 0, y: grid.height)
		while p.y < canvas.size.height {
			path.move(to: p)
			path.addLine(to: CGPoint(x: p.x + 4, y: p.y))
			p.y += grid.height
		}
		p.x += grid.width
		while p.x < canvas.size.width {
			path.move(to: p)
			path.addLine(to: CGPoint(x: p.x, y: p.y - 4))
			p.x += grid.height
		}
		axesLayer.frame = canvasView.bounds
		axesLayer.path = path.cgPath
	}
	
	/*private*/ lazy var contentView: UIView = {
		let view = UIView(frame: self.bounds)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = .clear
		self.addSubview(view)
		
		
		return view
	}()
	
	private lazy var axesLayer: CAShapeLayer = {
		let axesLayer = CAShapeLayer()
		axesLayer.fillColor = nil
		axesLayer.strokeColor = self.tintColor.withAlphaComponent(0.5).cgColor
		axesLayer.lineWidth = 1.0 / UIScreen.main.scale
		self.canvasView.layer.addSublayer(axesLayer)
		return axesLayer
	}()
	
	
	private lazy var xAxisView: UIView = {
		let view = UIView(frame: self.bounds)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = .clear
		self.contentView.addSubview(view)
		return view
	}()
	
	/*private*/ lazy var yAxisView: UIView = {
		let view = UIView(frame: self.bounds)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = .clear
		self.contentView.addSubview(view)
		return view
	}()
	
	/*private*/ lazy var zeroPointLabel: UILabel = {
		let label = UILabel(frame: self.bounds)
		label.textAlignment = .right
		label.translatesAutoresizingMaskIntoConstraints = false
		self.contentView.addSubview(label)
		return label
	}()
	
	/*private*/ lazy var canvasView: UIView = {
		let view = UIView(frame: self.bounds)
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = self.tintColor.withAlphaComponent(0.15)
		self.contentView.addSubview(view)
		return view
	} ()
	
	private var chartLayers: [(layer: CAShapeLayer, chart: LineChart)] = []
	
	private func rebuild() {
		updateConstraintsIfNeeded()
		
		let extraSpace: CGFloat
		if xAxis == nil && yAxis == nil {
			zeroPointLabel.attributedText = nil
			extraSpace = 0
		}
		else {
			let s = xAxis?.range.lowerBound == yAxis?.range.lowerBound
				? yAxis?.formatter?.string(for: yAxis!.range.lowerBound) ?? "0"
				: "\(yAxis?.formatter?.string(for: yAxis!.range.lowerBound) ?? "0")/\(xAxis?.formatter?.string(for: xAxis!.range.lowerBound) ?? "0")"
			zeroPointLabel.attributedText = NSAttributedString(string: s, attributes: textAttributes)
			extraSpace = 4
		}
		
		for constraint in contentView.constraints {
			guard (constraint.firstItem as? UIView) == canvasView && constraint.firstAttribute == .leading && constraint.secondAttribute == .trailing else {continue}
			constraint.constant = extraSpace
		}
		
		zeroPointLabel.sizeToFit()
		var canvasFrame = bounds
		canvasFrame.origin.x = zeroPointLabel.bounds.maxX + extraSpace
		canvasFrame.size.height -= zeroPointLabel.bounds.size.height
		canvasFrame.size.height -= canvasFrame.size.height.truncatingRemainder(dividingBy: grid.height)
		
		var n = Int((canvasFrame.size.height / grid.height).rounded(.toNearestOrAwayFromZero))
		canvasView.constraints.first (where: {return ($0.firstItem as? UIView) == canvasView && $0.firstAttribute == .height})?.constant = canvasFrame.size.height
		
		var labels = yAxisView.subviews.flatMap {$0 as? UILabel}
		if let axis = yAxis {
			let start = axis.range.upperBound > axis.range.lowerBound ? 1 : n
			let r = axis.range.upperBound - axis.range.lowerBound
			
			var prev: UILabel?
			for i in start...n {
				let label: UILabel
				if labels.isEmpty {
					label = UILabel(frame: .zero)
					label.textAlignment = .right
					label.translatesAutoresizingMaskIntoConstraints = false
					yAxisView.addSubview(label)
					NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[label]-0-|", options: [], metrics: nil, views: ["label": label]))
					label.centerYAnchor.constraint(equalTo: yAxisView.bottomAnchor, constant: -CGFloat(i) * grid.height).isActive = true
				}
				else {
					label = labels.removeFirst()
					yAxisView.constraints.first {($0.firstItem as? UILabel) == label && $0.firstAttribute == .centerY}!.constant = -CGFloat(i) * grid.height
				}
				prev = label
				NSLayoutConstraint.deactivate(yAxisView.constraints.filter {($0.firstItem as? UILabel) == label && $0.firstAttribute == .top})
				
				let value = Double(i) / Double(n) * r + axis.range.lowerBound
				let s = axis.formatter?.string(for: value) ?? "\(value)"
				label.attributedText = NSAttributedString(string: s, attributes: textAttributes)
				label.sizeToFit()
				canvasFrame.origin.x = max(canvasFrame.origin.x, label.bounds.maxX)
			}
			prev?.topAnchor.constraint(equalTo: yAxisView.topAnchor).isActive = true
		}
		labels.forEach {$0.removeFromSuperview()}
		canvasFrame.size.width = bounds.size.width - canvasFrame.minX
		canvasFrame.size.width -= canvasFrame.size.width.truncatingRemainder(dividingBy: grid.width)
		
		n = Int((canvasFrame.size.width / grid.width).rounded(.toNearestOrAwayFromZero))
		canvasView.constraints.first (where: {return ($0.firstItem as? UIView) == canvasView && $0.firstAttribute == .width})?.constant = canvasFrame.size.width
		
		labels = xAxisView.subviews.flatMap {$0 as? UILabel}
		if let axis = xAxis, axis.range.upperBound > axis.range.lowerBound {
			let r = axis.range.upperBound - axis.range.lowerBound
			
			var prev: UILabel?
			for i in 1...n {
				let label = !labels.isEmpty ? labels.removeFirst() : {
					let label = UILabel(frame: .zero)
					label.translatesAutoresizingMaskIntoConstraints = false
					xAxisView.addSubview(label)
					NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[label]-0-|", options: [], metrics: nil, views: ["label": label]))
					label.centerXAnchor.constraint(equalTo: xAxisView.leadingAnchor, constant: CGFloat(i) * grid.width).isActive = true
					return label
					}()
				prev = label
				
				let value = Double(i) / Double(n) * r + axis.range.lowerBound
				let s = axis.formatter?.string(for: value) ?? "\(value)"
				UIView.animate(withDuration: 0.25, animations: { 
					label.attributedText = NSAttributedString(string: s, attributes: self.textAttributes)
				})
			}
			prev?.trailingAnchor.constraint(equalTo: xAxisView.trailingAnchor).isActive = true
		}
		labels.forEach {$0.removeFromSuperview()}
		
		//var layers = chartLayers
		
		yAxisView.setNeedsLayout()
		xAxisView.setNeedsLayout()
		self.setNeedsLayout()
		self.layoutIfNeeded()

		canvasFrame = canvasView.frame
		
		chartLayers.map {$0.chart}.transition(to: charts) { (old, new, type) in
			switch type {
			case .delete:
				let layer = chartLayers[old!].layer
				chartLayers.remove(at: old!)
				
				let path = UIBezierPath(cgPath: layer.path!)
				var transform = CGAffineTransform(translationX: 0, y: canvasFrame.size.height)
				transform = transform.scaledBy(x: 1, y: 0)
				path.apply(transform)
				
				var delegate: AnimationDelegate? = AnimationDelegate()
				delegate?.didStopHandler = { _ in
					layer.removeFromSuperlayer()
					delegate?.didStopHandler = nil
					delegate = nil
				}
				
				let animation = CABasicAnimation(keyPath: "path")
				animation.fromValue = layer.path
				animation.toValue = path.cgPath
				animation.duration = 0.25
				animation.delegate = delegate
				layer.add(animation, forKey: "path")
				layer.path = path.cgPath
				
			case .insert:
				let chart = charts[new!]
				let layer = CAShapeLayer()
				layer.fillColor = nil
				layer.strokeColor = chart.color.cgColor
				canvasView.layer.addSublayer(layer)
				chartLayers.insert((layer: layer, chart: chart), at: new!)
				//chartLayers.append((layer: layer, chart: chart))
			case .move:
				let chart = charts[new!]
				let layer = chartLayers.remove(at: old!).layer
				layer.strokeColor = chart.color.cgColor
				chartLayers.insert((layer: layer, chart: chart), at: new!)
			case .update:
				let chart = charts[new!]
				let layer = chartLayers.remove(at: new!).layer
				layer.strokeColor = chart.color.cgColor
				chartLayers.insert((layer: layer, chart: chart), at: new!)
			}
		}
		
		/*for chart in charts {
			let layer = !layers.isEmpty ? layers.removeFirst() : {
				let layer = CAShapeLayer()
				layer.fillColor = nil
				canvasView.layer.addSublayer(layer)
				return (layer: layer, chart: chart)
				}()
			layer.layer.strokeColor = chart.color.cgColor
			chartLayers.append((layer: layer.layer, chart: chart))
		}
		layers.forEach {$0.layer.removeFromSuperlayer()}*/
		
//		UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState], animations: { 
//		}, completion: nil)
		
		for layer in chartLayers {
			layer.layer.frame = canvasView.bounds
			let path = layer.chart.path.copy() as! UIBezierPath
			path.apply(CGAffineTransform(scaleX: canvasFrame.size.width, y: canvasFrame.size.height))
			
			let from = layer.layer.path ?? {
				let from = path.copy() as! UIBezierPath
				var transform = CGAffineTransform(translationX: 0, y: canvasFrame.size.height)
				transform = transform.scaledBy(x: 1, y: 0)
				from.apply(transform)
				return from.cgPath
				}()
			
			let animation = CABasicAnimation(keyPath: "path")
			animation.fromValue = from
			animation.toValue = path.cgPath
			animation.duration = 0.25
			layer.layer.add(animation, forKey: "path")
			layer.layer.path = path.cgPath
		}

	}
	
}
*/
