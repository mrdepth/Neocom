//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

protocol P {
	
}

extension Int: P {}

func f<A: P, B: P>(_ a: A, _ b: B) {
	print("1")
}

func f<A: P, B: P>(_ a: A?, _ b: B?) {
	print("2")
}



f(1, 2)
let i: Int? = nil
f(1, i)
