//
//  PieChartView.swift
//  Chart
//
//  Created by Artem Shimanski on 28.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class PieSegment {
	var value: Double {
		didSet {
			chart?.didUpdateSegments()
		}
	}
	var formatter: Formatter?
	var color: UIColor
	var title: String?
	
	init(value: Double, formatter: Formatter? = nil, color: UIColor = .white, title: String? = nil) {
		self.value = value
		self.formatter = formatter
		self.color = color
		self.title = title
	}
	
	fileprivate weak var chart: PieChartView?
}

public class PieSegmentLayer: CALayer {
	@NSManaged public dynamic var start: CGFloat
	@NSManaged public dynamic var end: CGFloat
	
	var segment: PieSegment?
	
	override public  class func needsDisplay(forKey key: String) -> Bool {
		if key == "start" || key == "end" {
			return true
		}
		else {
			return super.needsDisplay(forKey: key)
		}
	}
	
	override public func action(forKey event: String) -> CAAction? {
		if event == "start" || event == "end" {
			let animation = CABasicAnimation(keyPath: event)
			animation.fromValue = self.presentation()?.value(forKey: event)
			animation.duration = 1.5
			animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
			return animation
		}
		else {
			return super.action(forKey: event)
		}
	}

	override public var bounds: CGRect {
		didSet {
			let path = UIBezierPath(arcCenter: position, radius: bounds.size.width / 2, startAngle: (start - 0.25) * CGFloat.pi * 2, endAngle: (end - 0.25) * CGFloat.pi * 2, clockwise: true)
			path.addLine(to: position)
		}
	}
	
	@nonobjc func path() -> UIBezierPath {
		let r = bounds.size.width / 2
		let from = (start - 0.25) * CGFloat.pi * 2
		let to = (end - 0.25) * CGFloat.pi * 2
		
		let path = UIBezierPath(arcCenter: position, radius: r, startAngle: from, endAngle: to, clockwise: true)
		path.addArc(withCenter: position, radius: r / 3, startAngle: to, endAngle: from, clockwise: false)
		return path
	}
	
	private lazy var textSize: CGSize = {
		let s = NSAttributedString(string: "\(self.model().segment!.value)", attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.preferredFont(forTextStyle: .footnote)])
		let rect = s.boundingRect(with: self.superlayer!.bounds.size, options: [.usesLineFragmentOrigin], context: nil)
		return rect.size
	}()
	
	override public func draw(in ctx: CGContext) {
		let path = self.path()
		ctx.setFillColor(model().segment!.color.cgColor)
		ctx.addPath(path.cgPath)
		ctx.fillPath()
		
		let s = NSAttributedString(string: "\(model().segment!.value)", attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.preferredFont(forTextStyle: .footnote)])
		var rect = s.boundingRect(with: bounds.size, options: [.usesLineFragmentOrigin], context: nil)

		let r = bounds.size.width / 2
		let from = (start - 0.25) * CGFloat.pi * 2
		let to = (end - 0.25) * CGFloat.pi * 2

		UIGraphicsPushContext(ctx)
		let p = CGPoint(x: r * 2.0 / 3.0 * cos((to + from) / 2),
		                y: r * 2.0 / 3.0 * sin((to + from) / 2))
		rect.origin.x = r + p.x - rect.size.width / 2
		rect.origin.y = r + p.y - rect.size.height / 2
		s.draw(in: rect)
		UIGraphicsPopContext()
		
//		super.draw(in: ctx)
	}
	
}

class PieChartView: UIView {
	
	var segments: [PieSegment] {
		return segmentLayers.flatMap {$0.segment}
	}
	
	func add(segment: PieSegment) {
		segment.chart = self
		let segmentLayer = PieSegmentLayer()
		segmentLayer.segment = segment
		
		
		
		segmentLayer.start = segmentLayers.flatMap {$0.presentation()?.end}.last ?? segmentLayers.last?.end ?? 0
		segmentLayer.end = segmentLayer.start
		
		segmentLayer.frame = layer.bounds
		
		segmentLayers.append(segmentLayer)
		layer.addSublayer(segmentLayer)

		DispatchQueue.main.async {
			self.didUpdateSegments()
		}
	}
	
	func remove(segment: PieSegment) {
		if let i = segmentLayers.index(where: {$0.segment === segment}) {
			segmentLayers[i].removeFromSuperlayer()
			segmentLayers.remove(at: i)
		}
		didUpdateSegments()
	}
	
	private var segmentLayers: [PieSegmentLayer] = []
	
	@objc fileprivate func didUpdateSegments() {
		var sum: Double = 0
		segments.forEach {sum += $0.value}
		var p: Double = 0
		for layer in segmentLayers {
			layer.start = CGFloat(p)
			p += sum == 0 ? 1.0 / Double(segmentLayers.count) : layer.segment!.value / sum
			layer.end = CGFloat(p)
		}
	}
	
	func removeAllSegments() {
		segmentLayers.forEach {$0.removeFromSuperlayer()}
		segmentLayers.removeAll()
	}
	
}
