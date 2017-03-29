//
//  NCLineChartView.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

class NCLineChartView: UIView {
	
	var grid: CGSize = CGSize(width: 24, height: 24)
	
	var xFormatter: Formatter = NCUnitFormatter(unit: .meter, style: .short, useSIPrefix: nil)
	var yFormatter: Formatter = NCUnitFormatter(unit: .none, style: .full, useSIPrefix: nil)
	var dimensions: (x: Double, y: Double) = (37845, 500)
	
	
	
	var layers: [CAShapeLayer] = []
	var charts: [(path: UIBezierPath, color: UIColor)] = [] {
		didSet {
			var old = layers
			var new = [CAShapeLayer]()
			let canvas = self.canvas
			
			func update(layer: CAShapeLayer, path: UIBezierPath) {
				let from = layer.path ?? {
					let from = path.copy() as! UIBezierPath
					var transform = CGAffineTransform(translationX: 0, y: canvas.size.height)
					transform = transform.scaledBy(x: 1, y: 0)
					from.apply(transform)
					return from.cgPath
					}()
				
				let animation = CABasicAnimation(keyPath: "path")
				animation.fromValue = from
				animation.toValue = path.cgPath
				animation.duration = 0.25
				layer.add(animation, forKey: "path")
				layer.path = path.cgPath
			}

			
			for (path, color) in charts {
				let layer = !old.isEmpty ? old.removeFirst() : {
					let layer = CAShapeLayer()
					layer.fillColor = nil
					self.layer.addSublayer(layer)
					return layer
					}()
				
				layer.strokeColor = color.cgColor
				layer.frame = canvas
				update(layer: layer, path: path)
				new.append(layer)
			}
			for layer in old {
				layer.removeFromSuperlayer()
			}
			
			self.layers = new
		}
	}
	
	private lazy var attributes: [String: Any] = {
		return [NSFontAttributeName: UIFont.preferredFont(forTextStyle: .footnote), NSForegroundColorAttributeName: UIColor.white]
	}()
	
	private var xCaptions: [(CGRect, NSAttributedString)] = []
	private var yCaptions: [(CGRect, NSAttributedString)] = []
	
	var canvas: CGRect {
		guard let x = xCaptions.first, let y = yCaptions.first else {return bounds}
		var canvas = bounds
		canvas.origin.x = x.0.maxX + 4
		canvas.size.width = trunc((bounds.size.width - canvas.origin.x) / grid.width) * grid.width
		canvas.size.height = trunc((bounds.size.height - y.0.size.height) / grid.height) * grid.height
		canvas.origin.y = y.0.minY - canvas.size.height
		return canvas
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		var s = NSAttributedString(string: "0", attributes:attributes)
		var zero = s.boundingRect(with: .zero, options: [.usesLineFragmentOrigin], context: nil)
		
		var y = bounds.size.height - zero.size.height
		
		zero.origin.x = -zero.size.width
		zero.origin.y = y - zero.size.height / 2
		
		let h = bounds.size.height - zero.size.height
		
		var prev = zero
		
		y -= grid.height
		
		var xCaptions = [(CGRect, NSAttributedString)]()
		xCaptions.append((zero, s))
		
		var minX = zero.origin.x
		if dimensions.y > 0 {
			while y > zero.size.height / 2 {
				
				s = NSAttributedString(string: yFormatter.string(for: Double((h - y) / h) * dimensions.y)!, attributes: attributes)
				var rect = s.boundingRect(with: .zero, options: [.usesLineFragmentOrigin], context: nil)
				rect.origin.x = -rect.size.width
				rect.origin.y = y - rect.size.height / 2
				if !prev.intersects(rect) {
					prev = rect
					xCaptions.append((rect, s))
					minX = min(rect.origin.x, minX)
				}
				y -= grid.height
			}
		}
		
		let transform = CGAffineTransform(translationX: -minX, y: 0)
		xCaptions = xCaptions.map { ($0.0.applying(transform), $0.1) }
		zero = zero.applying(transform)
		
		var yCaptions = [(CGRect, NSAttributedString)]()
		if dimensions.x > 0 {
			zero.size.width += 4
			var x = zero.maxX + grid.width
			let w = bounds.size.width - zero.maxX
			prev = zero
			while x < bounds.size.width {
				s = NSAttributedString(string: xFormatter.string(for: Double(x / w) * dimensions.x)!, attributes: attributes)
				var rect = s.boundingRect(with: .zero, options: [.usesLineFragmentOrigin], context: nil)
				rect.origin.x = x - rect.size.width
				rect.origin.y = bounds.size.height - rect.size.height
				
				if rect.maxX > bounds.size.width {
					break
				}
				
				if !prev.intersects(rect) {
					prev = rect
					yCaptions.append((rect, s))
				}
				
				
				x += grid.width
			}
		}
		
		self.xCaptions = xCaptions
		self.yCaptions = yCaptions
		
		let canvas = self.canvas
		for layer in layers {
			layer.frame = canvas
		}
	}
	
	override func draw(_ rect: CGRect) {
		UIColor.black.setFill()
		UIGraphicsGetCurrentContext()?.fill(rect)
		
		for s in xCaptions {
			s.1.draw(in: s.0)
		}
		for s in yCaptions {
			s.1.draw(in: s.0)
		}
		
		UIColor.lightGray.setStroke()
		let canvas = self.canvas
		
		let path = UIBezierPath()
		path.lineWidth = 1.0 / UIScreen.main.scale
		
		var p = CGPoint(x: canvas.minX, y: canvas.maxY)
		path.move(to: p)
		path.addLine(to: CGPoint(x: p.x, y: canvas.minY))
		while p.x < canvas.maxX {
			p.x += grid.width
			path.move(to: p)
			path.addLine(to: CGPoint(x: p.x, y: p.y - 4))
		}
		p = canvas.origin
		while p.y < canvas.maxY {
			path.move(to: p)
			path.addLine(to: CGPoint(x: p.x + 4, y: p.y))
			p.y += grid.height
		}
		path.move(to: p)
		path.addLine(to: CGPoint(x: canvas.maxX, y: p.y))
		path.stroke()
		
		super.draw(rect)
	}
	
}
