//
//  NCFittingModuleDamageChartView.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingModuleDamageChartView: UIView {
	var module: NCFittingModule? {
		didSet {
			self.setNeedsLayout()
		}
	}
	var targetSignature: Double = 100 {
		didSet {
			self.setNeedsLayout()
		}
	}
	
	private lazy var dpsLayer: CAShapeLayer = {
		let layer = CAShapeLayer()
		layer.frame = self.bounds
		layer.strokeColor = UIColor.green.cgColor
		layer.fillColor = nil
		self.layer.addSublayer(layer)
		return layer
	}()
	
	private lazy var hitChanceLayer: CAShapeLayer = {
		let layer = CAShapeLayer()
		layer.frame = self.bounds
		layer.backgroundColor = UIColor.clear.cgColor
		layer.strokeColor = UIColor.caption.cgColor
		layer.fillColor = nil
		self.layer.addSublayer(layer)
		return layer
	}()
	
	private lazy var axisLayer: CAShapeLayer = {
		let layer = CAShapeLayer()
		layer.frame = self.bounds
		layer.backgroundColor = UIColor.clear.cgColor
		layer.strokeColor = UIColor.lightGray.cgColor
		layer.fillColor = nil
		layer.lineWidth = 1.0 / UIScreen.main.scale
		self.layer.addSublayer(layer)
		return layer
	}()


	override func layoutSubviews() {
		super.layoutSubviews()
		axisLayer.frame = bounds
		dpsLayer.frame = bounds
		hitChanceLayer.frame = bounds
		reload()
	}
	
	private lazy var gate = NCGate()
	private func reload() {
		guard let module = self.module else {return}
		let bounds = self.bounds
		let n = Double(round(bounds.size.width / 5))
		let targetSignature = self.targetSignature
		gate.perform {
			module.engine?.performBlockAndWait {
				let hitChancePath = UIBezierPath()
				let dpsPath = UIBezierPath()

				guard let ship = module.owner as? NCFittingShip else {return}
				let optimal = module.maxRange
				let falloff = module.falloff
				let maxX = optimal + max(falloff * 2, optimal * 0.5)
				guard maxX > 0 else {return}
				let dx = maxX / n
				
				func dps(at range: Double, signature: Double = 0) -> Double {
					let angularVelocity = signature > 0 ? ship.maxVelocity(orbit: range) / range : 0
					return module.dps(target: NCFittingHostileTarget(angularVelocity: angularVelocity, velocity: 0, signature: signature, range: range)).total
				}
				
				let maxDPS = dps(at: optimal * 0.1)
				guard maxDPS > 0 else {return}
				
				var x: Double = dx
				hitChancePath.move(to: CGPoint(x: 0, y: maxDPS))
				hitChancePath.addLine(to: CGPoint(x: dx, y: maxDPS))
				
				dpsPath.move(to: CGPoint(x: x, y: dps(at:x, signature: targetSignature)))
				
				while x < maxX {
					x += dx
					hitChancePath.addLine(to: CGPoint(x: x, y: dps(at: x)))
					dpsPath.addLine(to: CGPoint(x: x, y: dps(at: x, signature: targetSignature)))
				}
				var transform = CGAffineTransform(scaleX: CGFloat(1.0 / maxX) * bounds.size.width, y: -CGFloat(1.0 / maxDPS) * bounds.size.height)
				transform = transform.translatedBy(x: 0, y: CGFloat(-maxDPS))
				
				hitChancePath.apply(transform)
				dpsPath.apply(transform)
				
				let axisPath = UIBezierPath()
				axisPath.move(to: CGPoint(x: 0, y: maxDPS))
				axisPath.addLine(to: .zero)
				axisPath.addLine(to: CGPoint(x: maxX, y: 0))
				
				x = optimal
				axisPath.move(to: CGPoint(x: x, y: 0))
				axisPath.addLine(to: CGPoint(x: x, y: dps(at: x)))

				x = optimal + falloff
				axisPath.move(to: CGPoint(x: x, y: 0))
				axisPath.addLine(to: CGPoint(x: x, y: dps(at: x)))

				axisPath.apply(transform)

				DispatchQueue.main.async {
					func update(layer: CAShapeLayer, path: CGPath) {
						if let from = layer.path {
							let animation = CABasicAnimation(keyPath: "path")
							animation.fromValue = from
							animation.toValue = path
							animation.duration = 0.25
							layer.add(animation, forKey: "path")
							layer.path = path
						}
						else {
							layer.path = path
						}
					}
					update(layer: self.hitChanceLayer, path: hitChancePath.cgPath)
					update(layer: self.dpsLayer, path: dpsPath.cgPath)
					update(layer: self.axisLayer, path: axisPath.cgPath)
				}
			}
		}
	}
}


