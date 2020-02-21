//
//  Math.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/25/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return max(limits.lowerBound, min(limits.upperBound, self))
    }
}

func * (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width * rhs.width, height: lhs.height * rhs.height)
}

func / (lhs: CGSize, rhs: CGSize) -> CGSize {
    return CGSize(width: lhs.width / rhs.width, height: lhs.height / rhs.height)
}

extension CGAffineTransform {
    init(scale: CGSize) {
        self.init(scaleX: scale.width, y: scale.height)
    }
    
    init(translation: CGPoint) {
        self.init(translationX: translation.x, y: translation.y)
    }

    func scaledBy(_ scale: CGSize) -> CGAffineTransform {
        return scaledBy(x: scale.width, y: scale.height)
    }
    
    func translatedBy(_ translation: CGPoint) -> CGAffineTransform {
        return translatedBy(x: translation.x, y: translation.y)
    }
}

prefix func - (lhs: CGPoint) -> CGPoint {
    return CGPoint(x: -lhs.x, y: -lhs.y)
}

func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
    return CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
}

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func - (lhs: CGPoint, rhs: CGSize) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
}

prefix func - (lhs: UIEdgeInsets) -> UIEdgeInsets {
    UIEdgeInsets(top: -lhs.top, left: -lhs.left, bottom: -lhs.bottom, right: -lhs.right)
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
