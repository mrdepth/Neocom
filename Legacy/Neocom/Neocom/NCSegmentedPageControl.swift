//
//  NCSegmentedControl.swift
//  Neocom
//
//  Created by Artem Shimanski on 12.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

//@IBDesignable
class NCSegmentedPageControl: UIControl, UIScrollViewDelegate {
	
	@IBInspectable var spacing: CGFloat = 15
	@IBInspectable var segments: String? {
		didSet {
			self.titles = segments?.components(separatedBy: "|") ?? []
		}
	}
	
	var titles: [String] = [] {
		didSet {
			var buttons = stackView.arrangedSubviews as? [UIButton] ?? []
			
			for title in titles {
				let button = !buttons.isEmpty ? buttons.removeFirst() : {
					let button = UIButton(frame: .zero)
					button.translatesAutoresizingMaskIntoConstraints = false
					button.setTitleColor(.white, for: .normal)
					button.addTarget(self, action: #selector(onButton(_:)), for: .touchUpInside)
					stackView.addArrangedSubview(button)
					return button
				}()
				
				button.setTitle(title, for: .normal)
				button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
			}
			buttons.forEach {$0.removeFromSuperview()}
			setNeedsLayout()
		}
	}
	
	@IBOutlet weak var scrollView: UIScrollView? {
		didSet {
			scrollView?.delegate = self
		}
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		tintColor = .caption
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	private lazy var contentView: UIScrollView = {
		let contentView = UIScrollView(frame: self.bounds)
		contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		contentView.delaysContentTouches = true
		contentView.canCancelContentTouches = true
		contentView.showsHorizontalScrollIndicator = false
		contentView.showsVerticalScrollIndicator = false
		self.addSubview(contentView)
		return contentView
	}()
	
	public lazy var stackView: UIStackView = {
		let stackView = UIStackView()
		stackView.alignment = .center
		stackView.distribution = .fillProportionally
		stackView.axis = .horizontal
		stackView.spacing = self.spacing
		stackView.translatesAutoresizingMaskIntoConstraints = false
		self.contentView.addSubview(stackView)
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(s)-[view]-(s)-|", options: [], metrics: ["s": self.spacing], views: ["view": stackView]))
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": stackView]))
//		NSLayoutConstraint(item: stackView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: self.contentView, attribute: .width, multiplier: 1, constant: -self.spacing * 2).isActive = true
		stackView.widthAnchor.constraint(greaterThanOrEqualTo: self.contentView.widthAnchor, constant: -self.spacing * 2).isActive = true
		stackView.heightAnchor.constraint(equalTo: self.contentView.heightAnchor).isActive = true
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
		
		var bounds = self.bounds
		bounds.size.height -= 4
		
		contentView.frame = bounds
		guard stackView.arrangedSubviews.count > 0 else {return}
		stackView.layoutIfNeeded()
		contentView.layoutIfNeeded()
		guard let scrollView = scrollView, scrollView.bounds.size.width > 0 else {return}
		let p = scrollView.contentOffset.x / scrollView.bounds.size.width
		
		let page = Int(round(p))
		let lastPage = (stackView.arrangedSubviews.count - 1)
		for (i, button) in (stackView.arrangedSubviews as! [UIButton]).enumerated() {
			button.setTitleColor(i == page ? tintColor : .lightText, for: .normal)
		}
		
		let fromLabel = stackView.arrangedSubviews[Int(trunc(p)).clamped(to: 0...lastPage)]
		let toLabel = stackView.arrangedSubviews[Int(ceil(p)).clamped(to: 0...lastPage)]
		
		var from = fromLabel.convert(fromLabel.bounds, to: contentView)
		var to = toLabel.convert(toLabel.bounds, to: contentView)
		if p < 0 {
			from.size.width = 0;
		}
		else if p > CGFloat(lastPage) {
			to.origin.x += to.size.width
			to.size.width = 0
		}
		
		var rect = from.lerp(to: to, t: 1.0 - (ceil(p) - p))
		rect.size.height = 3
		rect.origin.y = bounds.size.height - rect.size.height
		indicator.frame = rect
		let x = indicator.center.x - contentView.bounds.size.width / 2
		guard contentView.contentSize.width >= contentView.bounds.size.width else {return}
		contentView.contentOffset.x = x.clamped(to: 0...(contentView.contentSize.width - contentView.bounds.size.width))
	}
	
	override var intrinsicContentSize: CGSize {
		var size = self.contentView.contentSize
		size.height += 4
		return size
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
