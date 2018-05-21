//
//  PieChartView.swift
//  Chart
//
//  Created by Artem Shimanski on 28.04.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

fileprivate let halfSquare = (0.5 as CGFloat).squareRoot()

class PieSegment {
	var value: Double {
		didSet {
			if oldValue != value {
				DispatchQueue.main.async {
//					self.chart?.didUpdateSegments()
				}
				
			}
		}
	}
	var color: UIColor
	var title: String?
	
	init(value: Double, color: UIColor = .white, title: String? = nil) {
		self.value = value
		self.color = color
		self.title = title
	}
	
	fileprivate weak var chart: PieChartView?
}

public class PieSegmentLayer: CALayer {
	@NSManaged public var start: CGFloat
	@NSManaged public var end: CGFloat
	@NSManaged public var insets: CGFloat
	@NSManaged public var titleLocation: CGFloat
	@NSManaged public var value: Double
	
	var segment: PieSegment?
	var formatter: Formatter?
	
	override public  class func needsDisplay(forKey key: String) -> Bool {
		if key == "start" || key == "end" || key == "insets" || key == "titleLocation" || key == "value" {
			return true
		}
		else {
			return super.needsDisplay(forKey: key)
		}
	}
	
	override public func action(forKey event: String) -> CAAction? {
		if event == "start" || event == "end" || event == "insets" || event == "titleLocation" || event == "value" {
			let animation = CABasicAnimation(keyPath: event)
			animation.fromValue = self.presentation()?.value(forKey: event) ?? (self.animation(forKey: event) as? CABasicAnimation)?.fromValue ?? self.value(forKey: event)
			animation.duration = 1.0
			animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
			return animation
		}
		else {
			return super.action(forKey: event)
		}
	}

	fileprivate var preferredTitleSize: CGSize {
		let s = title
		let rect = s.boundingRect(with: self.superlayer!.bounds.size, options: [.usesLineFragmentOrigin], context: nil)
		return rect.size
	}
	
	fileprivate var title: NSAttributedString {
		var s = model().formatter?.string(for: value) ?? "\(model().value)"
		if let title = model().segment?.title {
			s = "\(title)\n\(s)"
		}
		let paragraph = NSMutableParagraphStyle()
		paragraph.alignment = .center
		return NSAttributedString(string: s, attributes: [NSAttributedStringKey.foregroundColor: model().segment!.color, NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .footnote),NSAttributedStringKey.paragraphStyle: paragraph])
	}
	
	fileprivate func titleFrame(at: CGFloat, size: CGSize) -> CGRect {
		let t = CGFloat.pi * 2 * (at - 0.25)
		let r = bounds.size.width / 2
//		let r2 = r + insets * halfSquare - insets
		let r2 = r + insets / 2 - insets
		return CGRect(x: r + r2 * cos(t) - size.width / 2, y: r + r2 * sin(t) - size.height / 2, width: size.width, height: size.height)
	}
	
	override public func draw(in ctx: CGContext) {
		
		ctx.saveGState()
		ctx.translateBy(x: insets, y: insets)
		
		let r = bounds.insetBy(dx: insets, dy: insets).size.width / 2
		let from = (start - 0.25) * CGFloat.pi * 2
		let to = (end - 0.25) * CGFloat.pi * 2
		
		let r0 = r / 2
		let r1 = r0 + 16
		let r2 = r - 4
		let a: CGFloat = (to - from) * r0 > 1 ? 0.5 : 0
		
		
		let position = CGPoint(x: r, y: r)
		var path = UIBezierPath(arcCenter: position, radius: r2, startAngle: from + a / r2, endAngle: to - a / r2, clockwise: true)
		path.addArc(withCenter: position, radius: r1, startAngle: to - a / r1, endAngle: from + a / r1, clockwise: false)
		ctx.addPath(path.cgPath)
		ctx.setFillColor(model().segment!.color.cgColor)
		ctx.fillPath()

		path = UIBezierPath(arcCenter: position, radius: r1 + 0.5, startAngle: from + a / r1, endAngle: to - a / r1, clockwise: true)
		path.addArc(withCenter: position, radius: r0, startAngle: to - a / r0, endAngle: from + a / r0, clockwise: false)
		ctx.addPath(path.cgPath)
		ctx.setFillColor(model().segment!.color.withAlphaComponent(0.9).cgColor)
		ctx.fillPath()

		
		ctx.restoreGState()
		
		let s = title
		
		UIGraphicsPushContext(ctx)
		
		let b = titleFrame(at: titleLocation, size: preferredTitleSize)
		var rect = s.boundingRect(with: b.size, options: [.usesLineFragmentOrigin], context: nil)
		
		rect.origin.x = b.origin.x + (b.size.width - rect.size.width) / 2
		rect.origin.y = b.origin.y + (b.size.height - rect.size.height) / 2
		
//		UIColor.cyan.setFill()
//		ctx.fill(rect)
		s.draw(with: rect, options: [.usesLineFragmentOrigin], context: nil)
		UIGraphicsPopContext()
	}
	
}

public class PieTotalLayer: CALayer {
	@NSManaged public var insets: CGFloat
	@NSManaged public var value: Double
	var formatter: Formatter?
	
	override public  class func needsDisplay(forKey key: String) -> Bool {
		if key == "insets" || key == "value" {
			return true
		}
		else {
			return super.needsDisplay(forKey: key)
		}
	}
	
	override public func action(forKey event: String) -> CAAction? {
		if event == "insets" || event == "value" {
			let animation = CABasicAnimation(keyPath: event)
			animation.fromValue = self.presentation()?.value(forKey: event)
			animation.duration = 1.0
			animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
			return animation
		}
		else {
			return super.action(forKey: event)
		}
	}
	
	fileprivate var title: NSAttributedString {
//		let s =  "\(NSLocalizedString("Total", comment: ""))\n\(formatter?.string(for: model().value) ?? "\(model().value)")"
		let s =  "\(model().formatter?.string(for: value) ?? "\(model().value)")"
		let paragraph = NSMutableParagraphStyle()
		paragraph.alignment = .center
		return NSAttributedString(string: s, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .subheadline),NSAttributedStringKey.paragraphStyle: paragraph])
	}

	override public func draw(in ctx: CGContext) {
		var bounds = self.bounds.insetBy(dx: insets, dy: insets)
		let r = bounds.size.width / 4.0 + 1
		bounds = bounds.insetBy(dx: r, dy: r)
		
		let path = UIBezierPath(ovalIn: bounds)
		
//		ctx.setFillColor(UIColor(white: 1.0, alpha: 0.9).cgColor)
		ctx.setFillColor(UIColor.separator.cgColor)
		ctx.addPath(path.cgPath)
		ctx.fillPath()

		let s = title
		var rect = s.boundingRect(with: bounds.size, options: [.usesLineFragmentOrigin], context: nil)
		
		rect.origin.x = bounds.midX - rect.size.width / 2
		rect.origin.y = bounds.midY - rect.size.height / 2
		
		UIGraphicsPushContext(ctx)

		s.draw(with: rect, options: [.usesLineFragmentOrigin], context: nil)
		UIGraphicsPopContext()

	
	}
}

class PieChartView: UIView {
	var formatter: Formatter?
	
	var segments: [PieSegment] {
		return segmentLayers.compactMap {$0.segment}
	}
	
	func add(segment: PieSegment) {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		if totalLayer == nil {
			totalLayer = PieTotalLayer()
			totalLayer?.needsDisplayOnBoundsChange = true
			totalLayer?.frame = bounds
			totalLayer?.value = 0
			totalLayer?.formatter = formatter
			totalLayer?.contentsScale = UIScreen.main.scale
			totalLayer?.insets = 0
			layer.addSublayer(totalLayer!)
		}

		segment.chart = self
		let segmentLayer = PieSegmentLayer()
		segmentLayer.contentsScale = UIScreen.main.scale
		segmentLayer.segment = segment
		segmentLayer.needsDisplayOnBoundsChange = true
		segmentLayer.masksToBounds = false
		segmentLayer.value = 0
		segmentLayer.formatter = formatter
		segmentLayer.insets = segmentLayers.first?.presentation()?.insets ?? segmentLayers.first?.insets ?? 0
		
		segmentLayer.start = segmentLayers.compactMap {$0.presentation()?.end}.last ?? segmentLayers.last?.end ?? 0
		segmentLayer.end = segmentLayer.start
		segmentLayer.titleLocation = segmentLayer.start
		
		segmentLayer.frame = layer.bounds
		
		segmentLayers.append(segmentLayer)
		layer.addSublayer(segmentLayer)

		CATransaction.commit()
//		DispatchQueue.main.async {
			self.didUpdateSegments()
//		}
	}
	
	func remove(segment: PieSegment) {
		if let i = segmentLayers.index(where: {$0.segment === segment}) {
			segmentLayers[i].removeFromSuperlayer()
			segmentLayers.remove(at: i)
		}
		didUpdateSegments()
		if segmentLayers.count == 0 {
			totalLayer?.removeFromSuperlayer()
			totalLayer = nil
		}
	}
	
	func removeAllSegments() {
		segmentLayers.forEach {$0.removeFromSuperlayer()}
		segmentLayers.removeAll()
		totalLayer?.removeFromSuperlayer()
		totalLayer = nil
	}

	private var segmentLayers: [PieSegmentLayer] = []
	private var totalLayer: PieTotalLayer?
	
	@objc fileprivate func didUpdateSegments() {
		var sum: Double = 0
		segments.forEach {sum += $0.value}
		var p: Double = 0
		
		var insets: CGFloat = 0
		var sizes: [CGSize] = []
		
		for layer in segmentLayers {
			let size = layer.preferredTitleSize
			let s = max(size.width, size.height)
			sizes.append(CGSize(width: s, height: s))
			
			insets = max(s, insets)
			layer.start = CGFloat(p)
			p += sum == 0 ? 1.0 / Double(segmentLayers.count) : layer.segment!.value / sum
			layer.end = CGFloat(p)
		}
		
		segmentLayers.forEach {$0.insets = insets; $0.value = $0.segment!.value}
		totalLayer?.insets = insets
		totalLayer?.value = sum
		
		let r = bounds.size.width / 2
		let r2 = r + insets / 2 - insets
		
		var locations = segmentLayers.map {($0.start + $0.end) / 2}

		for _ in 0..<10 {
			guard sizes.count > 1 else {break}
			var prev = sizes.count - 1
			var isFinished = true
			for i in 0..<sizes.count {
				let a = segmentLayers[prev].titleFrame(at: locations[prev], size: sizes[prev])
				let b = segmentLayers[i].titleFrame(at: locations[i], size: sizes[i])
				let intersection = a.intersection(b)
				if !intersection.isNull {
					let a = max(intersection.width, intersection.height) / r2 / (CGFloat.pi * 2)
					locations[prev] -= a / 4
					locations[i] += a / 4
					isFinished = false
				}
				prev = i
			}
			if isFinished {
				break
			}
		}
		
		for (i, location) in locations.enumerated() {
			segmentLayers[i].titleLocation = location
		}
	}
	
	
}
