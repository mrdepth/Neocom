//: Playground - noun: a place where people can play

import UIKit
import EVEAPI
import PlaygroundSupport

public func all<Value>(_ futures: [Future<Value>]) -> Future<[Value]> {
	let promise = Promise<[Value]>()
	var queue = futures
	var values = [Value]()
	values.reserveCapacity(futures.count)
	
	var pop: (() -> Void)!
	
	pop = {
		if queue.isEmpty {
			try! promise.fulfill(values)
			pop = nil
		}
		else {
			let first = queue.removeFirst()
			first.then { result in
				values.append(result)
				pop()
				}.catch {error in
					try! promise.fail(error)
					pop = nil
			}
		}
	}
	pop()
	return promise.future
}


let a = DispatchQueue.main.async {
	return 1
}

let b = DispatchQueue.main.async {
	return 2
}

let c = DispatchQueue.main.async {
	return 3
}


all([a, b, c]).then(on: .main) { result in
	print("\(result)")
	PlaygroundPage.current.finishExecution()
}

PlaygroundPage.current.needsIndefiniteExecution = true
