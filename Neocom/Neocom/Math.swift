//
//  Math.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

extension Int {
	func clamped(to: ClosedRange<Int>) -> Int {
		return Swift.max(to.lowerBound, Swift.min(to.upperBound, self))
	}
}

extension Double {
	func clamped(to: ClosedRange<Double>) -> Double {
		return max(to.lowerBound, min(to.upperBound, self))
	}
}

extension Float {
	func clamped(to: ClosedRange<Float>) -> Float {
		return max(to.lowerBound, min(to.upperBound, self))
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
    
    func insetBy(_ insets: UIEdgeInsets) -> CGRect {
        return UIEdgeInsetsInsetRect(self, insets)
    }

}


extension CGSize {
    func insetBy(_ insets: UIEdgeInsets) -> CGSize {
        return CGSize(width: width - insets.left - insets.right, height: height - insets.top - insets.bottom)
    }
}

extension CGPoint {
    public func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: x + dx, y: y + dy)
    }
}

extension UIEdgeInsets {
    func inverted() -> UIEdgeInsets {
        return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
    }
}
