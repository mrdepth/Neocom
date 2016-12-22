//: Playground - noun: a place where people can play

import UIKit
import EVEAPI

var history = [ESMarketHistory]()

let data = try! Data(contentsOf: Bundle.main.url(forResource: "market", withExtension: "json")!)
let array = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String:Any]]
array.forEach {
	history.append(ESMarketHistory(dictionary: $0)!)
}

let range = history.suffix(365).indices

let width = CGFloat(range.count)
let bounds = CGRect(x: 0, y: 0, width: width, height: width * 0.33).integral

let volume = UIBezierPath()
volume.move(to: CGPoint(x: 0, y: 0))

let donchian = UIBezierPath()
let avg = UIBezierPath()

var x: CGFloat = 0
var isFirst = true

var v = 0...0 as ClosedRange<Int>
var p = 0...0 as ClosedRange<Double>
let d = history[range.first!].date...history[range.last!].date


var dx = 0...0 as ClosedRange<Double>
var dx2 = 0...0 as ClosedRange<Double>
let n = Double(range.count)
for i in range {
	let item = history[i]
	let lowest = history[max(i - 4, 0)...i].min {
		$0.lowest < $1.lowest
		}!
	let highest = history[max(i - 4, 0)...i].max {
		$0.highest < $1.highest
		}!
	if isFirst {
		avg.move(to: CGPoint(x: x, y: CGFloat(item.average)))
		isFirst = false
	}
	else {
		avg.addLine(to: CGPoint(x: x, y: CGFloat(item.average)))
	}
	volume.append(UIBezierPath(rect: CGRect(x: x, y: 0, width: 1, height: CGFloat(item.volume))))
	donchian.append(UIBezierPath(rect: CGRect(x: x, y: CGFloat(lowest.lowest), width: 1, height: abs(CGFloat(highest.highest - lowest.lowest)))))
	x += 1
	
	v = min(v.lowerBound, item.volume)...max(v.upperBound, item.volume)
	p = min(p.lowerBound, lowest.lowest)...max(p.upperBound, highest.highest)
	dx = (dx.lowerBound + lowest.lowest / n)...(dx.upperBound + highest.highest / n)
	dx2 = (dx2.lowerBound + pow(lowest.lowest, 2) / n)...(dx2.upperBound + pow(highest.highest, 2) / n)
}


let highest = history.max {
	$0.highest < $1.highest
	}!

let deviationL = (dx2.lowerBound - pow(dx.lowerBound, 2))
sqrt(deviationL)
let deviationH = (dx2.upperBound - pow(dx.upperBound, 2))
sqrt(deviationH)
let mean = dx.lowerBound...dx.upperBound
let sigmaL = (mean.lowerBound - sqrt(deviationL) * 3)
let sigmaH = (mean.upperBound + sqrt(deviationH) * 3)
dx
dx2
donchian.close()

var transform = CGAffineTransform.identity
var rect = volume.bounds
if rect.size.width > 0 && rect.size.height > 0 {
	transform = transform.scaledBy(x: 1, y: -1)
	transform = transform.translatedBy(x: 0, y: -bounds.size.height)
	transform = transform.scaledBy(x: bounds.size.width / rect.size.width, y: bounds.size.height / rect.size.height * 0.25)
	transform = transform.translatedBy(x: -rect.origin.x, y: -rect.origin.y)
	volume.apply(transform)
}


rect = donchian.bounds.union(avg.bounds)
rect = avg.bounds
rect.origin.y = CGFloat(mean.lowerBound)
rect.size.height = CGFloat(mean.upperBound - mean.lowerBound)
if rect.size.width > 0 && rect.size.height > 0 {
	transform = CGAffineTransform.identity
	transform = transform.scaledBy(x: 1, y: -1)
	transform = transform.translatedBy(x: 0, y: -bounds.size.height * 0.75)
	transform = transform.scaledBy(x: bounds.size.width / rect.size.width, y: bounds.size.height / rect.size.height * 0.75)
	transform = transform.translatedBy(x: -rect.origin.x, y: -rect.origin.y)
	donchian.apply(transform)
	avg.apply(transform)
}

UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.main.scale)
UIBezierPath(rect: bounds).fill()
UIColor.lightGray.setFill()
donchian.fill()
UIColor.blue.setFill()
volume.fill()
UIColor.orange.setStroke()
avg.stroke()
let image = UIGraphicsGetImageFromCurrentImageContext()
UIGraphicsEndImageContext()
