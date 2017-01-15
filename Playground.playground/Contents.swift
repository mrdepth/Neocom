//: Playground - noun: a place where people can play

import UIKit
//import EVEAPI

extension Int {
	func clamped(to: ClosedRange<Int>) -> Int {
		return Swift.max(to.lowerBound, Swift.min(to.upperBound, self))
	}
}

extension CGFloat {
	func clamped(to: ClosedRange<CGFloat>) -> CGFloat {
		return fmax(to.lowerBound, fmin(to.upperBound, self))
	}
}


extension CGRect {
	func lerp(to: CGRect, t: CGFloat) -> CGRect {
		func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
			return a + (b - a) * t
		}
		
		var r = CGRect.zero
		r.origin.x = lerp(self.origin.x, to.origin.x, t)
		r.origin.y = lerp(self.origin.y, to.origin.y, t)
		r.size.width = lerp(self.size.width, to.size.width, t)
		r.size.height = lerp(self.size.height, to.size.height, t)
		return r
	}
}

class NCSegmentedPageControl: UIControl {
	@IBInspectable var spacing: CGFloat = 10
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
				button.setTitleColor(.black, for: .normal)
				stackView.addArrangedSubview(button)
			}
		}
	}
	
	@IBOutlet weak var scrollView: UIScrollView!
	
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
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[view]-10-|", options: [], metrics: nil, views: ["view": stackView]))
		NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": stackView]))
		NSLayoutConstraint(item: stackView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: self.contentView, attribute: .width, multiplier: 1, constant: 0).isActive = true
		return stackView
	}()
	
	public lazy var indicator: UIView = {
		let indicator = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 4))
		indicator.backgroundColor = UIColor.yellow
		self.contentView.addSubview(indicator)
		return indicator
	}()
	
	override func layoutSubviews() {
		super.layoutSubviews()
		contentView.frame = bounds
		guard stackView.arrangedSubviews.count > 0 else {return}
		let p = scrollView.contentOffset.x / scrollView.bounds.size.width
		
		let fromLabel = stackView.arrangedSubviews[Int(trunc(p)).clamped(to: 0...stackView.arrangedSubviews.count)]
		let toLabel = stackView.arrangedSubviews[Int(ceil(p)).clamped(to: 0...stackView.arrangedSubviews.count)]
		
		let from = fromLabel.convert(fromLabel.bounds, to: contentView)
		let to = toLabel.convert(toLabel.bounds, to: contentView)
		
		var rect = from.lerp(to: to, t: 1.0 - (ceil(p) - p))
		rect.size.height = 3
		rect.origin.y = bounds.size.height - rect.size.height
		indicator.frame = rect
		let x = indicator.center.x - contentView.bounds.size.width / 2
		contentView.contentOffset.x = x.clamped(to: 0...(contentView.contentSize.width - contentView.bounds.size.width))
	}
	
	override var intrinsicContentSize: CGSize {
		return contentView.contentSize
	}
}

let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 160))
let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 160))
window.addSubview(scrollView)
scrollView.contentSize = CGSize(width: 320 * 5, height: 160)
scrollView.contentOffset = CGPoint(x: 0, y: 0)

let pageControl = NCSegmentedPageControl(frame: CGRect(x: 0, y: 0, width: 320, height: 28))
pageControl.scrollView = scrollView
pageControl.segments = "SECTION1|PAGE2"
window.addSubview(pageControl)
window.makeKeyAndVisible()
window.layoutIfNeeded()
pageControl.setNeedsLayout()
pageControl.layoutIfNeeded()


window

