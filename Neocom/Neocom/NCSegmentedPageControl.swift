//
//  NCSegmentedControl.swift
//  Neocom
//
//  Created by Artem Shimanski on 12.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

@IBDesignable
class NCSegmentedPageControl: UIControl, UIScrollViewDelegate {
	@IBInspectable var spacing: CGFloat = 15
	@IBInspectable var segments: String? {
		didSet {
			self.titles = segments?.components(separatedBy: "|") ?? []
		}
	}
	
	var titles: [String] = [] {
		didSet {
			for title in titles {
				let button = UIButton(frame: .zero)
				button.setTitle(title, for: .normal)
				button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
				button.setTitleColor(.white, for: .normal)
				button.addTarget(self, action: #selector(onButton(_:)), for: .touchUpInside)
				stackView.addArrangedSubview(button)
			}
			setNeedsLayout()
		}
	}
	
	@IBOutlet weak var scrollView: UIScrollView? {
		didSet {
			scrollView?.delegate = self
		}
	}
	
	private lazy var contentView: UIScrollView = {
		let contentView = UIScrollView(frame: self.bounds)
		contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		self.addSubview(contentView)
		return contentView
	}()
	
	public lazy var stackView: UIStackView = {
		let stackView = UIStackView(frame: self.bounds)
		stackView.alignment = .center
		stackView.distribution = .fillProportionally
		stackView.axis = .horizontal
		stackView.spacing = self.spacing
		stackView.translatesAutoresizingMaskIntoConstraints = false
		self.contentView.addSubview(stackView)
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(s)-[view]-(s)-|", options: [], metrics: ["s": self.spacing], views: ["view": stackView]))
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": stackView]))
		NSLayoutConstraint(item: stackView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: self.contentView, attribute: .width, multiplier: 1, constant: -self.spacing * 2).isActive = true
		return stackView
	}()
	
	public lazy var indicator: UIView = {
		let indicator = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 4))
		indicator.backgroundColor = self.tintColor
		self.contentView.addSubview(indicator)
		return indicator
	}()
	
	override func layoutSubviews() {
		super.layoutSubviews()
		contentView.frame = bounds
		contentView.layoutIfNeeded()
		guard stackView.arrangedSubviews.count > 0 else {return}
		stackView.layoutIfNeeded()
		guard let scrollView = scrollView, scrollView.bounds.size.width > 0 else {return}
		let p = scrollView.contentOffset.x / scrollView.bounds.size.width
		
		let page = Int(round(p))
		let lastPage = (stackView.arrangedSubviews.count - 1)
		for (i, button) in (stackView.arrangedSubviews as! [UIButton]).enumerated() {
			button.setTitleColor(i == page ? tintColor : .lightText, for: .normal)
		}
		
		let fromLabel = stackView.arrangedSubviews[Int(trunc(p)).clamped(to: 0...lastPage)]
		let toLabel = stackView.arrangedSubviews[Int(ceil(p)).clamped(to: 0...lastPage)]
		
		let from = fromLabel.convert(fromLabel.bounds, to: contentView)
		let to = toLabel.convert(toLabel.bounds, to: contentView)
		
		var rect = from.lerp(to: to, t: 1.0 - (ceil(p) - p))
		rect.size.height = 3
		rect.origin.y = bounds.size.height - rect.size.height
		indicator.frame = rect
		let x = indicator.center.x - contentView.bounds.size.width / 2
		guard contentView.contentSize.width >= contentView.bounds.size.width else {return}
		contentView.contentOffset.x = x.clamped(to: 0...(contentView.contentSize.width - contentView.bounds.size.width))
	}
	
	override var intrinsicContentSize: CGSize {
		return contentView.contentSize
	}
	
	@IBAction private func onButton(_ sender: UIButton) {
		guard let i = stackView.arrangedSubviews.index(of: sender) else {return}
		guard let scrollView = scrollView else {return}
		scrollView.setContentOffset(CGPoint(x: CGFloat(i) * scrollView.bounds.size.width, y: 0), animated: true)
	}
	
	// MARK: UIScrollViewDelegate
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		self.setNeedsLayout()
	}
}
