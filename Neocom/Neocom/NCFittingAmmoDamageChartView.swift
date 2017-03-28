//
//  NCFittingAmmoDamageChartView.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

fileprivate let ChartColors: [UIColor] = [#colorLiteral(red: 0.9411764706, green: 0.9764705882, blue: 0.9098039216, alpha: 1), #colorLiteral(red: 0.7294117647, green: 0.8941176471, blue: 0.737254902, alpha: 1), #colorLiteral(red: 0.4823529412, green: 0.8, blue: 0.768627451, alpha: 1), #colorLiteral(red: 0.262745098, green: 0.6352941176, blue: 0.7921568627, alpha: 1), #colorLiteral(red: 0.03137254902, green: 0.4078431373, blue: 0.6745098039, alpha: 1)]

class AnimationDelegate: NSObject, CAAnimationDelegate {
	var didStopHandler: ((CAAnimation, Bool) -> Void)?
	public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		didStopHandler?(anim ,flag)
	}
	
}

class NCFittingAmmoDamageChartView: UIView {
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

	var charges: [Int] {
		set {
			let from = charges
			from.transition(to: newValue) { old, new, type in
				switch type {
				case .insert:
					let color = colors.removeFirst()
					let shapeLayer = CAShapeLayer()
					shapeLayer.fillColor = nil
					shapeLayer.strokeColor = color.cgColor
					layers.append((newValue[new!], shapeLayer))
					self.layer.addSublayer(shapeLayer)
				case .delete:
					let layer = layers[old!].1
					
					colors.insert(UIColor(cgColor: layer.strokeColor!))
					layers.remove(at: old!)

					let path = UIBezierPath(cgPath: layer.path!)
					var transform = CGAffineTransform(translationX: 0, y: self.bounds.size.height)
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

				default:
					break
				}
			}
			setNeedsLayout()
		}
		get {
			return layers.map({$0.0})
		}
	}
	private var layers: [(Int, CAShapeLayer)] = []
	
	func color(for charge: Int) -> UIColor? {
		guard let color = layers.first (where: {$0.0 == charge})?.1.strokeColor else {return nil}
		return UIColor(cgColor: color)
	}
	
	private var colors: Set<UIColor> = Set([#colorLiteral(red: 0.9411764706, green: 0.9764705882, blue: 0.9098039216, alpha: 1), #colorLiteral(red: 0.7294117647, green: 0.8941176471, blue: 0.737254902, alpha: 1), #colorLiteral(red: 0.4823529412, green: 0.8, blue: 0.768627451, alpha: 1), #colorLiteral(red: 0.262745098, green: 0.6352941176, blue: 0.7921568627, alpha: 1), #colorLiteral(red: 0.03137254902, green: 0.4078431373, blue: 0.6745098039, alpha: 1)])
	
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
					
					path.move(to: CGPoint(x: x, y: dps(at:x, signature: targetSignature)))

					while x < maxX {
						x += dx
						path.addLine(to: CGPoint(x: x, y: dps(at: x, signature: targetSignature)))
					}
					paths.append(path)
					size.height = max(size.height, path.bounds.maxY)
				}
				
				module.charge = charge
				
				var transform = CGAffineTransform(scaleX: 1.0 / size.width * bounds.size.width, y: -1.0 / size.height * bounds.size.height)
				transform = transform.translatedBy(x: 0, y: -size.height)
				
				for path in paths {
					path.apply(transform)
				}
				
				DispatchQueue.main.async {
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
	}

}
