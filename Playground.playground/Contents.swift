//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

class NCSkillLevelView: UIView {
	
	var layers: [CALayer] = []
	var level: Int = 0 {
		didSet {
			layers.enumerated().forEach {
				$0.element.backgroundColor = $0.offset < level ? UIColor.gray.cgColor : UIColor.clear.cgColor
			}
		}
	}
	
	private var animation: (CALayer, CABasicAnimation)? {
		didSet {
			if let old = oldValue {
				old.0.removeAnimation(forKey: "backgroundColor")
			}
		}
	}
	
	var isTraining: Bool = false {
		didSet {
			animation = nil

			if (1...5).contains(level) {
				let layer = layers[level - 1]
				let animation = CABasicAnimation(keyPath: "backgroundColor")
				animation.fromValue = tintColor.cgColor
				animation.toValue = UIColor.white.cgColor
				animation.duration = 0.5
				animation.repeatCount = .greatestFiniteMagnitude
				animation.autoreverses = true
				layer.add(animation, forKey: "backgroundColor")
				self.animation = (layer, animation)
			}
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		layers = (0..<5).map { i in
			let layer = CALayer()
			layer.backgroundColor = tintColor.cgColor
//			layer.borderColor = UIColor.blue.cgColor
//			layer.borderWidth = 0.5
			self.layer.addSublayer(layer)
			return layer
		}
		
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	
	convenience init() {
		self.init(frame: .zero)
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		var rect = CGRect.zero
		rect.size.width = (bounds.width - CGFloat(layers.count) - 1) / CGFloat(layers.count)
		rect.size.height = min(bounds.height, 5)
		rect.origin.y = (bounds.height - rect.height) / 2
		rect.origin.x = 1
		rect = rect.integral
		
		for layer in layers {
			layer.frame = rect
			rect.origin.x += rect.size.width + 1
		}
	}

	override var intrinsicContentSize: CGSize {
		return CGSize(width: 8 * 5 + 6, height: 7)
	}
}


let view = UIView(frame: CGRect(x: 0, y: 0, width: 128, height: 128))

let levelView = NCSkillLevelView()
levelView.frame.size = levelView.intrinsicContentSize
levelView.level = 4
levelView.isTraining = true

view.addSubview(levelView)

PlaygroundPage.current.liveView = view
