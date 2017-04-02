//
//  NCFittingModuleDamageChartView.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class AnimationDelegate: NSObject, CAAnimationDelegate {
	var didStopHandler: ((CAAnimation, Bool) -> Void)?
	public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		didStopHandler?(anim ,flag)
	}
}


class NCFittingModuleDamageChartView: LineChartView {
	var module: NCFittingModule? {
		didSet {
			self.setNeedsLayout()
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(reload), object: nil)
			perform(#selector(reload), with: nil, afterDelay: 0)
		}
	}
	var targetSignature: Double = 100 {
		didSet {
			self.setNeedsLayout()
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(reload), object: nil)
			perform(#selector(reload), with: nil, afterDelay: 0)
		}
	}
	
	private lazy var gate = NCGate()
	@objc private func reload() {
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
				let maxX = ceil((optimal + max(falloff * 2, optimal * 0.5)) / 10000) * 10000
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
				
				x += dx
				while x < maxX {
					hitChancePath.addLine(to: CGPoint(x: x, y: dps(at: x)))
					dpsPath.addLine(to: CGPoint(x: x, y: dps(at: x, signature: targetSignature)))
					x += dx
				}
				var transform = CGAffineTransform(scaleX: CGFloat(1.0 / maxX), y: -CGFloat(1.0 / maxDPS))
				transform = transform.translatedBy(x: 0, y: -CGFloat(maxDPS))
				
				hitChancePath.apply(transform)
				dpsPath.apply(transform)
				
				let axisPath = UIBezierPath()

				x = optimal
				axisPath.move(to: CGPoint(x: x, y: 0))
				axisPath.addLine(to: CGPoint(x: x, y: dps(at: x)))
				
				x = optimal + falloff
				axisPath.move(to: CGPoint(x: x, y: 0))
				axisPath.addLine(to: CGPoint(x: x, y: dps(at: x)))
				
				axisPath.apply(transform)
				
				
				let accuracy = module.accuracy(targetSignature: targetSignature)
				
				
				DispatchQueue.main.async {
					self.charts = [LineChart(path: dpsPath, color: accuracy.color, identifier: 0), LineChart(path: hitChancePath, color: .caption, identifier: 1), LineChart(path: axisPath, color: UIColor(white: 1.0, alpha: 0.3), identifier: 2)]
				}
			}
		}
	}
}


