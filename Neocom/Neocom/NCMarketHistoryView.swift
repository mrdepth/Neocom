//
//  NCMarketHistoryView.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

//@IBDesignable
class NCMarketHistoryView: UIView {
	private var donchianRange: ClosedRange<Double>?
	private var volumeRange: ClosedRange<Double>?
	
	var donchian: UIBezierPath? {
		didSet {
			if let donchian = donchian {
				let bounds = donchian.bounds
				let h = bounds.size.height / (1.0 - NCMarketHistoryView.ratio)
				donchianRange = (Double(bounds.maxY - h))...Double(bounds.maxY)
			}
			else {
				donchianRange = nil
			}
			setNeedsDisplay()
		}
	}
	
	var volume: UIBezierPath? {
		didSet {
			if let volume = volume {
				let bounds = volume.bounds
				let h = bounds.size.height / NCMarketHistoryView.ratio
				volumeRange = 0...Double(h)
			}
			else {
				volumeRange = nil
			}
			setNeedsDisplay()
		}
	}
	var median: UIBezierPath? {
		didSet {
			setNeedsDisplay()
		}
	}
	var date: ClosedRange<Date>? {
		didSet {
			setNeedsDisplay()
		}
	}
	
	private static let gridSize = CGSize(width: 32, height: 32)
	private static let ratio = 0.33 as CGFloat
	
	override func draw(_ rect: CGRect) {
		var canvas = self.bounds.insetBy(dx: 60, dy: 0)
		canvas.origin.y = 20
		canvas.size.height -= 20
//		var canvas = self.bounds
		UIColor(white: 0.0, alpha:0.1).setFill()
		UIBezierPath(rect: canvas).fill()
		let context = UIGraphicsGetCurrentContext()
		context?.saveGState()
		context?.translateBy(x: canvas.origin.x, y: canvas.origin.y)
		
		canvas.origin = CGPoint.zero
		drawDonchianAndMedian(canvas: canvas)
		drawVolume(canvas: canvas)
		drawGrid(canvas: canvas)
		
		context?.restoreGState()
//		UIColor.red.setFill()
//		UIBezierPath(rect: rect).fill()

	}
	
	func drawVolume(canvas: CGRect) {
		guard let volume = volume?.copy() as? UIBezierPath else {return}
		
		var transform = CGAffineTransform.identity
		let rect = volume.bounds
		if rect.size.width > 0 && rect.size.height > 0 {
			transform = transform.scaledBy(x: 1, y: -1)
			transform = transform.translatedBy(x: 0, y: -canvas.size.height)
			transform = transform.scaledBy(x: canvas.size.width / rect.size.width, y: canvas.size.height / rect.size.height * NCMarketHistoryView.ratio)
			transform = transform.translatedBy(x: -rect.origin.x, y: -rect.origin.y)
			volume.apply(transform)
		}
		
		UIColor(number: 0x00d5ff44).setFill()
		volume.fill()
	}
	
	func drawDonchianAndMedian(canvas: CGRect) {
		guard let donchian = donchian?.copy() as? UIBezierPath,
			let median = median?.copy() as? UIBezierPath
			else {
				return
		}
		
		var transform = CGAffineTransform.identity
		let rect = donchian.bounds
		if rect.size.width > 0 && rect.size.height > 0 {
			transform = CGAffineTransform.identity
			transform = transform.scaledBy(x: 1, y: -1)
			transform = transform.translatedBy(x: 0, y: -canvas.size.height * (1.0 - NCMarketHistoryView.ratio))
			transform = transform.scaledBy(x: canvas.size.width / rect.size.width, y: canvas.size.height / rect.size.height * (1.0 - NCMarketHistoryView.ratio))
			transform = transform.translatedBy(x: -rect.origin.x, y: -rect.origin.y)
			donchian.apply(transform)
			median.apply(transform)
		}
		
		UIColor(white: 1, alpha: 0.1).setFill()
		donchian.fill()
		UIColor(number: 0x00d5ff77).setStroke()
		median.stroke()
	}
	
	private static let months = [NSLocalizedString("Jan", comment: ""), NSLocalizedString("Feb", comment: ""), NSLocalizedString("Mar", comment: ""), NSLocalizedString("Apr", comment: ""), NSLocalizedString("May", comment: ""), NSLocalizedString("Jun", comment: ""), NSLocalizedString("Jul", comment: ""), NSLocalizedString("Aug", comment: ""), NSLocalizedString("Sep", comment: ""), NSLocalizedString("Oct", comment: ""), NSLocalizedString("Nov", comment: ""), NSLocalizedString("Dec", comment: "")]
	
	
	func drawGrid(canvas: CGRect) {
		guard let donchianRange = donchianRange else {return}
		guard let volumeRange = volumeRange else {return}
		guard let dates = self.date else {return}
		
		let gridSize = NCMarketHistoryView.gridSize
		var y = 0 as CGFloat
		let grid = UIBezierPath()
		
		let attributes: [String: Any] = [NSFontAttributeName: UIFont.systemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white]
		let size = CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
		
		var donchian = donchianRange.upperBound
		let donchianStep = (donchianRange.upperBound - donchianRange.lowerBound) * Double(gridSize.height / canvas.size.height)
		var volume = volumeRange.upperBound
		let volumeStep = (volumeRange.upperBound - volumeRange.lowerBound) * Double(gridSize.height / canvas.size.height)
		
		while y <= canvas.size.height {
			grid.move(to: CGPoint(x: 0, y: y))
			grid.addLine(to: CGPoint(x: canvas.size.width, y: y))
			
			if (donchian > 0) {
				let s = NSAttributedString(string: NCUnitFormatter.localizedString(from: donchian, unit: .none, style: .short), attributes: attributes)
				var rect = s.boundingRect(with: size, options: [], context: nil)
				rect.origin.x = -rect.size.width - 4
				rect.origin.y = y - rect.size.height / 2
				if rect.maxY < canvas.size.height {
					s.draw(in: rect)
				}
				donchian -= donchianStep
			}
			
			if y >= canvas.height * (1.0 - NCMarketHistoryView.ratio) {
				let s = NSAttributedString(string: NCUnitFormatter.localizedString(from: round(volume), unit: .none, style: .short), attributes: attributes)
				var rect = s.boundingRect(with: size, options: [], context: nil)
				rect.origin.x = canvas.maxX + 4
				rect.origin.y = y - rect.size.height / 2
				if rect.maxY < canvas.size.height {
					s.draw(in: rect)
				}
			}
			volume -= volumeStep
			y += gridSize.height
		}
		
		
		let dateRange = dates.lowerBound.timeIntervalSinceReferenceDate...dates.upperBound.timeIntervalSinceReferenceDate
		var date = dateRange.lowerBound
		let dateStep = (dateRange.upperBound - dateRange.lowerBound) * Double(gridSize.width / canvas.size.width)
		let calendar = Calendar(identifier: .gregorian)
		var month = calendar.component(.month, from: dates.lowerBound)
		
		var x = 0 as CGFloat
		while x <= canvas.size.width {
			grid.move(to: CGPoint(x: x, y: 0))
			grid.addLine(to: CGPoint(x: x, y: canvas.size.height))
			
			let m = calendar.component(.month, from: Date(timeIntervalSinceReferenceDate: date))
			if m != month {
				month = m
				
				let s = NSAttributedString(string: NCMarketHistoryView.months[month - 1], attributes: attributes)
				var rect = s.boundingRect(with: size, options: [], context: nil)
				rect.origin.x = x - rect.size.width / 2
				rect.origin.y -= rect.size.height + 4
				if rect.maxX < canvas.size.width {
					s.draw(in: rect)
				}
				
			}
			
			date += dateStep
			x += gridSize.width
		}
		
		UIColor(white: 1.0, alpha: 0.1).setStroke()
		grid.lineWidth = 1.0 / UIScreen.main.scale
		grid.stroke()
	}
}
