//
//  SkillCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/23/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class SkillCell: RowCell {
	@IBOutlet weak var iconView: UIImageView?
	@IBOutlet weak var titleLabel: UILabel?
	@IBOutlet weak var levelLabel: UILabel?
	@IBOutlet weak var spLabel: UILabel?
	@IBOutlet weak var trainingTimeLabel: UILabel?
	@IBOutlet weak var progressView: UIProgressView?
	
	@IBOutlet weak var skillLevelView: SkillLevelView?
}

extension Prototype {
	enum SkillCell {
		static let `default` = Prototype(nib: UINib(nibName: "SkillCell", bundle: nil), reuseIdentifier: "SkillCell")
	}
}

class SkillLevelView: UIView {
	
	var layers: [CALayer] = []
	var level: Int = 0 {
		didSet {
			layers.enumerated().forEach {
				$0.element.backgroundColor = $0.offset < level ? UIColor.gray.cgColor : UIColor.clear.cgColor
			}
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateAnimation), object: nil)
			perform(#selector(updateAnimation), with: nil, afterDelay: 0)
		}
	}
	
	private var animation: (CALayer, CABasicAnimation)? {
		didSet {
			if let old = oldValue {
				old.0.removeAnimation(forKey: "backgroundColor")
			}
		}
	}
	
	var isActive: Bool = false {
		didSet {
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateAnimation), object: nil)
			perform(#selector(updateAnimation), with: nil, afterDelay: 0)
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		layers = (0..<5).map { i in
			let layer = CALayer()
			layer.backgroundColor = tintColor.cgColor
			self.layer.addSublayer(layer)
			return layer
		}
		layer.borderColor = tintColor.cgColor
		layer.borderWidth = ThinnestLineWidth
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		layers = (0..<5).map { i in
			let layer = CALayer()
			layer.backgroundColor = tintColor.cgColor
			self.layer.addSublayer(layer)
			return layer
		}
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
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
	
	override func didMoveToWindow() {
		super.didMoveToWindow()
		if window == nil {
			animation = nil
		}
		else if animation == nil {
			NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateAnimation), object: nil)
			perform(#selector(updateAnimation), with: nil, afterDelay: 0)
		}
	}
	
	@objc private func updateAnimation() {
		self.animation = nil
		if self.isActive && (1...5).contains(self.level) {
			let layer = self.layers[self.level - 1]
			let animation = CABasicAnimation(keyPath: "backgroundColor")
			animation.fromValue = self.tintColor.cgColor
			animation.toValue = UIColor.white.cgColor
			animation.duration = 0.5
			animation.repeatCount = .greatestFiniteMagnitude
			animation.autoreverses = true
			layer.add(animation, forKey: "backgroundColor")
			self.animation = (layer, animation)
		}
	}
}
