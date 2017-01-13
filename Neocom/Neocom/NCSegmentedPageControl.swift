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
	@IBInspectable var titleInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
	
	@IBInspectable var segments: String? {
		didSet {
			self.titles = segments?.components(separatedBy: "|") ?? []
		}
	}
	
	@IBOutlet weak var scrollView: UIScrollView!

	var font: UIFont = UIFont.preferredFont(forTextStyle: .subheadline)

	private lazy var contentView: UIScrollView = {
		let scrollView = UIScrollView(frame: self.bounds)
		scrollView.backgroundColor = .clear
		scrollView.delegate = self
		scrollView.showsVerticalScrollIndicator = false
		scrollView.showsHorizontalScrollIndicator = false
		scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		scrollView.translatesAutoresizingMaskIntoConstraints = true
		scrollView.isOpaque = false

		let maskingView = UIView(frame: self.bounds)
		maskingView.backgroundColor = .clear
		

		let mask = CAGradientLayer()
		mask.colors = [UIColor(white: 1.0, alpha: 0.0).cgColor, UIColor(white: 1.0, alpha: 1.0).cgColor, UIColor(white: 1.0, alpha: 1.0).cgColor, UIColor(white: 1.0, alpha: 0.0).cgColor]
		mask.locations = [0, 0.25, 0.75, 1.0]
		mask.startPoint = .zero
		mask.endPoint = CGPoint(x: 1, y: 0)
		
		maskingView.layer.mask = mask
		maskingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		maskingView.translatesAutoresizingMaskIntoConstraints = true

		self.addSubview(maskingView)
		maskingView.addSubview(scrollView)
		return scrollView
	}()
	
	private lazy var leftIndicator: UIImageView = {
		let imageView = UIImageView(image: #imageLiteral(resourceName: "indicatorLeft").withRenderingMode(.alwaysTemplate))
		imageView.tintColor = self.tintColor
		imageView.contentMode = .center
		self.insertSubview(imageView, aboveSubview: self.contentView)

		imageView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint(item: imageView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 10).isActive = true
		NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
		
		return imageView
	}()

	private lazy var rightIndicator: UIImageView = {
		let imageView = UIImageView(image: #imageLiteral(resourceName: "indicatorRight").withRenderingMode(.alwaysTemplate))
		imageView.tintColor = self.tintColor
		imageView.contentMode = .center
		self.insertSubview(imageView, aboveSubview: self.contentView)
		
		imageView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint(item: imageView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -10).isActive = true
		NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0).isActive = true

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
				contentView.addSubview(label)
			}
			setNeedsLayout()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(sender:))))
	}
	
	@objc private func onTap(sender: UITapGestureRecognizer) {
		guard labels.count > 0 else {return}
		var p = scrollView.contentOffset.x / scrollView.bounds.size.width
		var x = sender.location(in: self).x / self.bounds.size.width
		if x < 0.25 {
			p -= 1
		}
		if x >= 0.75 {
			p += 1
		}
		p = round(p).clamped(to: 0...CGFloat(labels.count - 1))
		
		x = scrollView.bounds.size.width * p
		scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		let mask = contentView.superview!.layer.mask as! CAGradientLayer
		mask.frame = bounds
		
		contentView.superview?.frame = bounds
		contentView.frame = bounds
		
		let w = max(labels.map({$0.intrinsicContentSize.width}).max() ?? 0 + 20, bounds.size.width / 3.0)
		let inset = (bounds.size.width - w) / 2
		let rect = CGRect(x: 0, y: 0, width: w, height: bounds.size.height)
		
		//var center = self.convert(CGPoint(x: bounds.midX, y: bounds.midY), to: contentView)
		var center = CGPoint(x: w / 2, y: rect.size.height / 2)
		for label in labels {
			label.bounds = rect
			label.center = center
			center.x += rect.size.width
		}
		contentView.contentSize = CGSize(width: center.x - rect.size.width / 2, height: rect.maxY)
		contentView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)

		if scrollView.contentSize.width > 0 {
			let x = scrollView.contentOffset.x / scrollView.contentSize.width * contentView.contentSize.width - contentView.contentInset.left
			contentView.contentOffset = CGPoint(x: x, y: 0)
		}
	}
	
	// MARK: UIScrollViewDelegate
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		guard self.scrollView.contentSize.width > 0 else {return}
		guard self.contentView.contentSize.width > 0 else {return}
		
		if scrollView === contentView && (scrollView.isDragging || scrollView.isDecelerating) {
			let x = (scrollView.contentOffset.x + scrollView.contentInset.left) / scrollView.contentSize.width * self.scrollView.contentSize.width
			self.scrollView.contentOffset = CGPoint(x: x, y: 0)
		}
		else if scrollView === self.scrollView {
			let x = scrollView.contentOffset.x / scrollView.contentSize.width * contentView.contentSize.width - contentView.contentInset.left
			contentView.contentOffset = CGPoint(x: x, y: 0)
		}
		
		let p = self.scrollView.contentOffset.x / self.scrollView.bounds.size.width
		
		for (i, label) in labels.enumerated() {
			let x = (abs(p - CGFloat(i))).clamped(to: 0...1)
			let s = cos(x * CGFloat.pi / 2) * (1.0 - 0.7) + 0.7
			
			label.transform = CGAffineTransform(scaleX: s, y: s)
		}
		
		leftIndicator.tintColor = p > 0.5 ? tintColor : .darkGray
		rightIndicator.tintColor = p < CGFloat(labels.count - 1) - 0.5 ? tintColor : .darkGray
	}
	
	func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		if scrollView === contentView {
			var point = targetContentOffset.pointee
			
			var x = (point.x + scrollView.contentInset.left) / scrollView.contentSize.width * self.scrollView.contentSize.width / self.scrollView.bounds.size.width
			x = round(x.clamped(to: 0...CGFloat(labels.count - 1)))
			x = x * scrollView.bounds.size.width / self.scrollView.contentSize.width * scrollView.contentSize.width - scrollView.contentInset.left
			point.x = x
			targetContentOffset.pointee = point
		}
	}
	
}
