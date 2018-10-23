//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

PlaygroundPage.current.needsIndefiniteExecution

let note = NSNotification.Name("note")
let obs = NotificationCenter.default.addObserver(forName: note, object: nil, queue: nil) { (n) in
	print(note)
}


var o: Deallocator<NSObjectProtocol>? = onDeinit(obs) {
	NotificationCenter.default.removeObserver($0)
}

NotificationCenter.default.post(name: note, object: nil)
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
	print("0.5")
	NotificationCenter.default.post(name: note, object: nil)
	DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
		print("1.0")
		NotificationCenter.default.post(name: note, object: nil)
		o = nil
	}
}

class Deallocator<T> {
	var block: (T) -> Void
	var base: T
	init(_ base: T, _ block: @escaping (T) -> Void) {
		self.block = block
		self.base = base
	}
	
	deinit {
		block(base)
	}
}

func onDeinit<T>(_ base: T, _ block: @escaping (T) -> Void) -> Deallocator<T> {
	return Deallocator<T>(base, block)
}
