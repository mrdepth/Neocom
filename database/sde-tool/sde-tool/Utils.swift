//
//  Extensions.swift
//  sde-tool
//
//  Created by Artem Shimanski on 20.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

extension NSArray {
	func validate(keyPath: String, with: NSArray) throws {
		for (i, value1) in enumerated() {
			switch (value1, with[i]) {
			case let (dic1 as NSDictionary, dic2 as NSDictionary):
				try dic1.validate(keyPath: keyPath, with: dic2)
			case let (arr1 as NSArray, arr2 as NSArray):
				try arr1.validate(keyPath: keyPath, with: arr2)
			case let (obj1 as Double, obj2 as Double) where obj1.distance(to: obj2) < 0.00001:
				break
			case let (obj1 as NSObject, obj2 as NSObject) where obj1.isEqual(obj2):
				break
			default:
				throw DumpError.schemaIsInvalid(keyPath)
			}
		}
	}
}

extension NSDictionary {
	func validate(keyPath: String, with: NSDictionary) throws {
		for (key, value1) in self {
			let subkey = "\(keyPath).\(key)"
			switch (value1, with[key]) {
			case let (dic1 as NSDictionary, dic2 as NSDictionary):
				try dic1.validate(keyPath: subkey, with: dic2)
			case let (arr1 as NSArray, arr2 as NSArray):
				try arr1.validate(keyPath: subkey, with: arr2)
			case let (obj1 as Double, obj2 as Double) where obj1.distance(to: obj2) < 0.00001:
				break
			case let (obj1 as NSObject, obj2 as NSObject) where obj1.isEqual(obj2):
				break
			default:
				throw DumpError.schemaIsInvalid(subkey)
			}
		}
	}
}

enum DumpError: Error {
	case fileNotFound
	case schemaIsInvalid(String)
	case parserError(URL, Error)
}



func load<T: Codable>(_ url: URL) -> Future<T> {
	let future = Future<T>()
	future.work = DispatchWorkItem { [weak future] in
		do {
			print("\(url.path)")
			let data = try Data(contentsOf: url)
			let json = try JSONDecoder().decode(T.self, from: data)
			let inverse = try JSONEncoder().encode(json)
			let obj1 = try JSONSerialization.jsonObject(with: data, options: [])
			let obj2 = try JSONSerialization.jsonObject(with: inverse, options: [])
			
			if let dic1 = obj1 as? NSDictionary, let dic2 = obj2 as? NSDictionary {
				try dic1.validate(keyPath: "", with: dic2)
			}
			else if let arr1 = obj1 as? NSArray, let arr2 = obj2 as? NSArray {
				try arr1.validate(keyPath: "", with: arr2)
			}
			future?.value = json
		}
		catch {
			future?.error = DumpError.parserError(url, error)
		}
	}
	DispatchQueue.global(qos: .utility).async(execute: future.work!)
	return future
}

class Future<T> {
	var work: DispatchWorkItem?
	var value: T!
	var error: Error?
	
	func get() throws -> T {
		work?.wait()
		if let error = error {
			throw error
		}
		return value
	}
}
