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
	@IBInspectable var selectedSegmentIndex: Float = 0 {
		didSet {
			let x = (scrollView.contentSize.width - scrollView.contentInset.left) * CGFloat(selectedSegmentIndex) / CGFloat(labels.count)
			scrollView.setContentOffset(CGPoint(x: x - scrollView.contentInset.left, y:0), animated: false)
		}
	}
	
	@IBInspectable var spacing: CGFloat = 20
	var font: UIFont? = UIFont.preferredFont(forTextStyle: .subheadline)
	@IBInspectable var segments: String? {
		didSet {
			self.titles = segments?.components(separatedBy: "|") ?? []
		}
	}
	
	private lazy var scrollView: UIScrollView = {
		let scrollView = UIScrollView(frame: self.bounds)
		scrollView.backgroundColor = .clear
		scrollView.delegate = self
		scrollView.showsVerticalScrollIndicator = false
		scrollView.showsHorizontalScrollIndicator = false
		self.addSubview(scrollView)
		return scrollView
	}()
	
	private lazy var leftIndicator: UIImageView = {
		let imageView = UIImageView(image: #imageLiteral(resourceName: "indicatorLeft").withRenderingMode(.alwaysTemplate))
		imageView.tintColor = self.tintColor
		imageView.contentMode = .center
		self.insertSubview(imageView, aboveSubview: self.scrollView)
		return imageView
	}()

	private lazy var rightIndicator: UIImageView = {
		let imageView = UIImageView(image: #imageLiteral(resourceName: "indicatorRight").withRenderingMode(.alwaysTemplate))
		imageView.tintColor = self.tintColor
		imageView.contentMode = .center
		self.insertSubview(imageView, aboveSubview: self.scrollView)
		return imageView
	}()

	private var labels: [UILabel] = []
	
	private var titles: [String] = [] {
		didSet {
			for label in labels {
				label.removeFromSuperview()
			}
			
			for title in titles {
				let label = UILabel(frame: bounds)
				label.text = title
				label.font = font
				label.textColor = tintColor
				label.textAlignment = .center
				labels.append(label)
				scrollView.addSubview(label)
			}
			
			invalidateIntrinsicContentSize()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(sender:))))
	}
	
	@objc private func onTap(sender: UITapGestureRecognizer) {
		var sel = selection()
		var x = sender.location(in: self).x / self.bounds.size.width
		if x < 0.25 {
			sel -= 1
		}
		if x >= 0.75 {
			sel += 1
		}
		sel = round(sel).clamped(to: 0...Float(labels.count - 1))
		
		x = (scrollView.contentSize.width - scrollView.contentInset.left) * CGFloat(sel) / CGFloat(labels.count)
		scrollView.setContentOffset(CGPoint(x: x - scrollView.contentInset.left, y:0), animated: true)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		leftIndicator.frame = CGRect(origin: .zero, size: CGSize(width: bounds.size.height, height: bounds.size.height))
		rightIndicator.frame = CGRect(origin: CGPoint(x:bounds.maxX - bounds.size.height, y:0), size: CGSize(width: bounds.size.height, height: bounds.size.height))
		
		guard labels.count > 0 else {return}
		scrollView.frame = bounds
		var maxSize = CGSize.zero
		for label in labels {
			let size = label.intrinsicContentSize
			maxSize.width = max(maxSize.width, size.width)
			maxSize.height = max(maxSize.height, size.height)
		}
		let count = CGFloat(labels.count)
		maxSize.width = max(maxSize.width, bounds.size.width / 3.0)
		maxSize.height = bounds.size.height
		
		var rect = CGRect(origin: .zero, size: maxSize)
		for label in labels {
			label.frame = rect
			rect.origin.x += rect.size.width
		}
		
		scrollView.contentSize = CGSize(width: rect.maxX, height: rect.maxY)
		var insets = UIEdgeInsets.zero
		insets.left = (bounds.size.width - maxSize.width) / 2
		scrollView.contentInset = insets
		
		let x = (scrollView.contentSize.width - insets.left) * CGFloat(selectedSegmentIndex) / count
		scrollView.contentOffset = CGPoint(x: x - insets.left, y:0)

	}

	// MARK: UIScrollViewDelegate
	
	private func selection() -> Float {
		let count = CGFloat(labels.count)
		let x = scrollView.contentOffset.x
		let insets = scrollView.contentInset
		return Float((x + insets.left) * count / (scrollView.contentSize.width - insets.left))
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		let sel = selection()
		self.leftIndicator.tintColor = sel > 0.5 ? self.tintColor : .darkGray
		self.rightIndicator.tintColor = sel < Float(labels.count - 1) - 0.5 ? self.tintColor : .darkGray
		for (i, label) in labels.enumerated() {
			let x = (abs(Double(sel) - Double(i))).clamped(to: 0...1)
			let s = CGFloat(cos(x * Double.pi / 2) * (1.0 - 0.7) + 0.7)
			
			label.transform = CGAffineTransform(scaleX: s, y: s)
		}
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		selectedSegmentIndex = selection()
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if !decelerate {
			selectedSegmentIndex = selection()
		}
	}
	
	func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
		selectedSegmentIndex = selection()
	}
	
	func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		var point = targetContentOffset.pointee
		
		let count = CGFloat(labels.count)
		let x = point.x
		let insets = scrollView.contentInset
		let sel = round(Float((x + insets.left) * count / (scrollView.contentSize.width - insets.left))).clamped(to: 0...(Float(count) - 1))
		point.x = (scrollView.contentSize.width - scrollView.contentInset.left) * CGFloat(sel) / CGFloat(labels.count) - insets.left
		targetContentOffset.pointee = point
	}

}
