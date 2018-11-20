//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

var r = CGRect(x: 0, y: 0.33, width: 100, height: 50)
withUnsafePointer(to: &r) { p in
	let ptr = UnsafeRawPointer(p)
	print(ptr)
	ptr.bind
}

