//
//  Extensions.swift
//  sde-tool
//
//  Created by Artem Shimanski on 20.02.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreText
import Cocoa

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
			case let (obj1 as Double, obj2 as Double) where abs(obj1) > 0 || obj1.distance(to: obj2) / obj1 < 0.001:
				break
			case let (obj1 as NSNumber, obj2 as NSNumber) where abs(obj1.doubleValue) > 0 || obj1.doubleValue.distance(to: obj2.doubleValue) / obj1.doubleValue < 0.001:
				break
			case let (obj1 as NSObject, obj2 as NSObject) where obj1.isEqual(obj2):
				break
            case (is NSNull, nil):
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
	case invalidUniverse(String)
	case npcStationsConflict
}

func load<T: Codable>(_ url: URL, type: T.Type = T.self) throws -> T {
	do {
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
		return json
	}
	catch {
		throw DumpError.parserError(url, error)
	}
	
}

extension OperationQueue {
	func detach<T>(_ block: @escaping () throws -> T) -> Future<T> {
		let promise = Promise<T>()
		let operation = BlockOperation {
			let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
			context.parent = mainContext
//			let observer = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: nil) { note in
//				if note.object as? NSManagedObjectContext != context {
//					context.perform {
//						context.mergeChanges(fromContextDidSave: note)
//					}
//				}
//			}
			
			NSManagedObjectContext.current = context
			context.performAndWait {
				do {
					try promise.set(.success(block()))
					if context.hasChanges {
						try context.save()
					}
				}
				catch {
					print("\(error)")
					exit(EXIT_FAILURE)
					//				promise.set(.failure(error))
				}
			}
//			NotificationCenter.default.removeObserver(observer)
			NSManagedObjectContext.current = nil
		}
		promise.future = Future<T>(operation: operation)
		addOperation(operation)
		return promise.future
	}
}

class Promise<T> {
	var future: Future<T>! = nil
	fileprivate func set(_ result: Result<T>) {
		future.result = result
	}
}

fileprivate enum Result<T> {
	case success(T)
	case failure(Error)
}

class Future<T> {
	
	init(operation: Operation) {
		self.operation = operation
	}
	
	fileprivate var result: Result<T>!
	fileprivate weak var operation: Operation?

	var value: T? {
		operation?.waitUntilFinished()
		switch result {
		case let .success(value)?:
			return value
		default:
			return nil
		}
	}
	
	var error: Error? {
		operation?.waitUntilFinished()
		switch result {
		case let .failure(error)?:
			return error
		default:
			return nil
		}
	}
	
	func get() throws -> T {
		operation?.waitUntilFinished()
		switch result! {
		case let .success(value):
			return value
		case let .failure(error):
			throw error
		}
	}
}

enum SDEDgmppItemCategoryID: Int32 {
	case none = 0
	case hi
	case med
	case low
	case rig
	case subsystem
	case mode
	case charge
	case drone
	case fighter
	case implant
	case booster
	case ship
	case structure
	case service
	case structureFighter
	case structureRig
    case cargo
}

enum SDEDgmAttributeID: Int {
	case metaGroup = 1692
	case metaLevel = 633
}

enum NCDBRegionID: Int {
	case whSpace = 11000000
}

//var allColors = Set<String>()
let colorMap: [String: [NSAttributedString.Key: Any]] = [
    "#ff3399cc": [.colorName: "primary"],
    "0xFFFF0000": [.colorName: "security0.0"],
    "0xFFE53300": [.colorName: "security0.1"],
    "0xFFFF4D00": [.colorName: "security0.2"],
    "0xFFFF6600": [.colorName: "security0.3"],
    "0xFFE58000": [.colorName: "security0.4"],
    "0xFF00FF00": [.colorName: "security0.7"],
    "0xFF4DFFCC": [.colorName: "security0.9"],
    "0xFF33FFFF": [.colorName: "security1.0"],
    "0xff0099FF": [.colorName: "primary"],
    "0xff00CC00": [.colorName: "primary"],
    "white": [.colorName: "primary"],
    "yellow": [.colorName: "primary"]
]

extension NSColor {
	
	public convenience init(number: UInt) {
		var n = number
		var abgr = [CGFloat]()

		for _ in 0...3 {
			let byte = n & 0xFF
			abgr.append(CGFloat(byte) / 255.0)
			n >>= 8
		}

		self.init(red: abgr[3], green: abgr[2], blue: abgr[1], alpha: abgr[0])
	}

	public convenience init?(string: String) {
//        allColors.insert(string)
		let scanner = Scanner(string: string)
		var rgba: UInt32 = 0
		if scanner.scanHexInt32(&rgba) {
			self.init(number:UInt(rgba))
		}
		else {
			let key = string.capitalized
			guard let color = NSColorList.availableColorLists.compactMap ({$0.color(withKey: NSColor.Name(key))}).first else {return nil}
			self.init(cgColor: color.cgColor)
		}
	}
}

extension NSAttributedString.Key {
    static let fontDescriptorSymbolicTraits = NSAttributedString.Key("UIFontDescriptorSymbolicTraits")
    static let colorName = NSAttributedString.Key("ColorName")
}

extension NSAttributedString {
	convenience init(html: String) {
		var html = html
		html = html.replacingOccurrences(of: "<br>", with: "\n", options: [.caseInsensitive], range: nil)
		html = html.replacingOccurrences(of: "<p>", with: "\n", options: [.caseInsensitive], range: nil)
		
		let s = NSMutableAttributedString(string: html)
		
		let options: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
		
		var expression = try! NSRegularExpression(pattern: "<(a[^>]*href|url)=[\"']?(.*?)[\"']?>(.*?)<\\/(a|url)>", options: options)
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.range(at: 3)).mutableCopy() as! NSMutableAttributedString
			let url = URL(string: s.attributedSubstring(from: result.range(at: 2)).string.replacingOccurrences(of: " ", with: ""))
			replace.addAttribute(NSAttributedStringKey.link, value: url!, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.range(at: 0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "<b[^>]*>(.*?)</b>", options: options)
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.range(at: 1)).mutableCopy() as! NSMutableAttributedString
            replace.addAttribute(.fontDescriptorSymbolicTraits, value: CTFontSymbolicTraits.boldTrait.rawValue, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.range(at: 0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "<i[^>]*>(.*?)</i>", options: options)
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.range(at: 1)).mutableCopy() as! NSMutableAttributedString
            replace.addAttribute(.fontDescriptorSymbolicTraits, value: CTFontSymbolicTraits.italicTrait.rawValue, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.range(at: 0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "<u[^>]*>(.*?)</u>", options: options)
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.range(at: 1)).mutableCopy() as! NSMutableAttributedString
			replace.addAttribute(NSAttributedStringKey.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.range(at: 0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "<(font)?[^>]*color\\s*=[\"']?(.*?)[\"']?\\s*?>(.*?)<\\/(color|font)>", options: [.caseInsensitive])
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let key = s.attributedSubstring(from: result.range(at: 2)).string
			let replace = s.attributedSubstring(from: result.range(at: 3)).mutableCopy() as! NSMutableAttributedString
			if let attributes = colorMap[key] {
                replace.addAttributes(attributes, range: NSMakeRange(0, replace.length))
//				replace.addAttribute(NSAttributedStringKey.foregroundColor, value: color, range: NSMakeRange(0, replace.length))
			}
            else {
                fatalError("Unknown color \(key)")
            }
			s.replaceCharacters(in: result.range(at: 0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "</?.*?>", options: options)
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			s.replaceCharacters(in: result.range(at: 0), with: NSAttributedString(string: ""))
		}
		
		self.init(attributedString: s)
	}
}

extension String {
	static let regex = try! NSRegularExpression(pattern: "\\\\u(.{4})", options: [.caseInsensitive])
	func replacingEscapes() -> String {
		let s = NSMutableString(string: self)
		for result in String.regex.matches(in: self, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let hexString = s.substring(with: result.range(at: 1))
			let scanner = Scanner(string: hexString)
			var i: UInt32 = 0
			if !scanner.scanHexInt32(&i) {
				exit(EXIT_FAILURE)
			}
			s.replaceCharacters(in: result.range(at: 0), with: String(unichar(i)))
		}
		s.replaceOccurrences(of: "\\r", with: "", options: [], range: NSMakeRange(0, s.length))
		s.replaceOccurrences(of: "\\n", with: "\n", options: [], range: NSMakeRange(0, s.length))
		return String(s)
	}
}



