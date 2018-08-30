//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

class A {
	func f() {
		print("f")
	}
	
	deinit {
		print("deinit")
	}
}

func ff() {
	var a: A? = A()
	
	func f() {
		a?.f()
	}
//	let f = {
//		a?.f()
//	}
	
	a?.f()
	
	DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
		print("async")
		//print(a)
		f()
		//a = nil
		DispatchQueue.main.async {
			PlaygroundPage.current.finishExecution()
		}
	}
	
	print("end")
}

ff()

//a = nil
PlaygroundPage.current.needsIndefiniteExecution
