//
//  NCFittingAmmoDamageChartView.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

/*let NCFittingAmmoDamageChartViewColorsLimit = 5

//fileprivate let ChartColors: [UIColor] = [#colorLiteral(red: 0.5529411765, green: 0.8274509804, blue: 0.7803921569, alpha: 1), #colorLiteral(red: 1, green: 1, blue: 0.7019607843, alpha: 1), #colorLiteral(red: 0.7450980392, green: 0.7294117647, blue: 0.8549019608, alpha: 1), #colorLiteral(red: 0.9843137255, green: 0.5019607843, blue: 0.4470588235, alpha: 1), #colorLiteral(red: 0.5019607843, green: 0.6941176471, blue: 0.8274509804, alpha: 1)]
fileprivate let ChartColors: [UIColor] = {
	var colors = [UIColor]()
	
	
	for i in 0..<NCFittingAmmoDamageChartViewColorsLimit {
		colors.append(UIColor(hue: CGFloat(i) / CGFloat(NCFittingAmmoDamageChartViewColorsLimit), saturation: 0.5, brightness: 1.0, alpha: 1.0))
	}
	
	return colors
}()

class NCFittingAmmoDamageChartView: ChartView {
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
		
		let charges = _charges
		
		gate.perform {
			module.engine?.performBlockAndWait {
				guard let ship = module.owner as? NCFittingShip else {return}
				let charge = module.charge
				
				func dps(at range: Double, signature: Double = 0) -> Double {
					let angularVelocity = signature > 0 ? ship.maxVelocity(orbit: range) / range : 0
					return module.dps(target: NCFittingHostileTarget(angularVelocity: angularVelocity, velocity: 0, signature: signature, range: range)).total
				}
				
				var paths = [UIBezierPath]()
				var size = CGSize.zero
				
				var statistics = [Int: (dps: Double, range: Double)]()
				
				for (typeID, _) in charges {
					module.charge = NCFittingCharge(typeID: typeID)
					
					let optimal = module.maxRange
					let falloff = module.falloff
					let maxX = ceil((optimal + max(falloff * 3, optimal * 0.5)) / 10000) * 10000
					guard maxX > 0 else {continue}
					let maxDPS = dps(at: optimal * 0.1)
					guard maxDPS > 0 else {return}
					
					
					
					let path = UIBezierPath()
					let dx = maxX / n
					var x: Double = dx
					
					var y = dps(at:x, signature: targetSignature)
					path.move(to: CGPoint(x: x, y: y))
					
					var best = (dps: y, range: x)
					while x < maxX {
						x += dx
						y = dps(at: x, signature: targetSignature)
						if y > best.dps {
							best = (dps: y, range: x)
						}
						path.addLine(to: CGPoint(x: x, y: y))
					}
					size.width = max(size.width, CGFloat(x))

					paths.append(path)
					size.height = max(size.height, path.bounds.maxY)
					
					statistics[typeID] = best
					
				}
				module.charge = charge
				
				var transform = CGAffineTransform(scaleX: 1.0 / size.width, y: -1.0 / size.height)
				transform = transform.translatedBy(x: 0, y: -size.height)
				
				for path in paths {
					path.apply(transform)
				}

				DispatchQueue.main.async {
					self.updateHandler?(statistics)
					self.charts = charges.enumerated().map({ (i, charge) -> LineChart in
						return LineChart(path: paths[i], color: charge.1, identifier: charge.0)
					})
				}
			}
		}
	}

	
	
	var charges: [Int] {
		set {
			let from = charges
			from.transition(to: newValue) { old, new, type in
				switch type {
				case .insert:
					let color = colors.removeFirst()
					_charges.append((newValue[new!], color))
				case .delete:
					let color = _charges[old!].1
					colors.insert(color)
					_charges.remove(at: old!)
				default:
					break
				}
			}
			self.setNeedsLayout()
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(reload), object: nil)
			perform(#selector(reload), with: nil, afterDelay: 0)
		}
		get {
			return _charges.map({$0.0})
		}
	}
	
	private var _charges: [(Int, UIColor)] = []
	
	func color(for charge: Int) -> UIColor? {
		guard let color = _charges.first (where: {$0.0 == charge})?.1 else {return nil}
		return color
	}
	
	var updateHandler: (([Int: (dps: Double, range: Double)]) -> Void)?
	
	private var colors: Set<UIColor> = Set(ChartColors)
	
	/*private lazy var axisLayer: CAShapeLayer = {
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
		
		let axisPath = UIBezierPath()
		axisPath.move(to: .zero)
		axisPath.addLine(to: CGPoint(x: 0, y: bounds.size.height))
		axisPath.addLine(to: CGPoint(x: bounds.size.width, y: bounds.size.height))
		axisLayer.path = axisPath.cgPath
		
		for (_, layer) in layers {
			layer.frame = bounds
		}
		reload()
	}
	
	
	/*func add(charge: Int) {
		let color = ChartColors[charges.count]
		let shapeLayer = CAShapeLayer()
		shapeLayer.fillColor = nil
		shapeLayer.strokeColor = color.cgColor
		charges.append((charge, shapeLayer))
		layer.addSublayer(shapeLayer)
		setNeedsLayout()
	}
	
	func remove(charge: Int) {
		guard let i = charges.index(where: {$0.0 == charge}) else {return}
		charges[i].1.removeFromSuperlayer()
		charges.remove(at: i)
	}*/
	
	private lazy var gate = NCGate()
	private func reload() {
		guard let module = self.module else {return}
		let bounds = self.bounds
		let n = Double(round(bounds.size.width / 5))
		let targetSignature = self.targetSignature
		let layers = self.layers
		
		gate.perform {
			module.engine?.perform {
				guard let ship = module.owner as? NCFittingShip else {return}
				let charge = module.charge

				func dps(at range: Double, signature: Double = 0) -> Double {
					let angularVelocity = signature > 0 ? ship.maxVelocity(orbit: range) / range : 0
					return module.dps(target: NCFittingHostileTarget(angularVelocity: angularVelocity, velocity: 0, signature: signature, range: range)).total
				}
				
				var paths = [UIBezierPath]()
				var size = CGSize.zero

				var statistics = [Int: (dps: Double, range: Double)]()
				
				for (typeID, _) in layers {
					module.charge = NCFittingCharge(typeID: typeID)
					
					let optimal = module.maxRange
					let falloff = module.falloff
					let maxX = ceil((optimal + max(falloff * 3, optimal * 0.5)) / 10000) * 10000
					guard maxX > 0 else {continue}
					let maxDPS = dps(at: optimal * 0.1)
					guard maxDPS > 0 else {return}
					
					size.width = max(size.width, CGFloat(maxX))
					
					
					let path = UIBezierPath()
					let dx = maxX / n
					var x: Double = dx

					var y = dps(at:x, signature: targetSignature)
					path.move(to: CGPoint(x: x, y: y))

					var best = (dps: y, range: x)
					while x < maxX {
						x += dx
						y = dps(at: x, signature: targetSignature)
						if y > best.dps {
							best = (dps: y, range: x)
						}
						path.addLine(to: CGPoint(x: x, y: y))
					}
					paths.append(path)
					size.height = max(size.height, path.bounds.maxY)
					
					statistics[typeID] = best

				}
				module.charge = charge
				
				var transform = CGAffineTransform(scaleX: 1.0 / size.width * bounds.size.width, y: -1.0 / size.height * bounds.size.height)
				transform = transform.translatedBy(x: 0, y: -size.height)
				
				for path in paths {
					path.apply(transform)
				}
				
				DispatchQueue.main.async {
					self.updateHandler?(statistics)
					func update(layer: CAShapeLayer, path: UIBezierPath) {
						let from = layer.path ?? {
							let from = path.copy() as! UIBezierPath
							//var transform = CGAffineTransform(scaleX: 1, y: 0)
							//transform = transform.translatedBy(x: 0, y: bounds.size.height)
							var transform = CGAffineTransform(translationX: 0, y: bounds.size.height)
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
					for (i, (_, layer)) in layers.enumerated() {
						update(layer: layer, path: paths[i])
					}
				}
			}
		}
	}*/

}
*/
