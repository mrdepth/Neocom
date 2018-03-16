//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData

func f<T>(_ type: T) {
	switch T.self {
	case is String.Type:
		print("String")
	default:
		print("Unknown")
	}
}

let d: String  = "10"
f(d)

do {
	JSONSerialization.isValidJSONObject(d)
	
//	try JSONDecoder().decode(String.self, from: data)
//	let data = try JSONEncoder().encode(d)
}
catch {
	print("\(error)")
}
