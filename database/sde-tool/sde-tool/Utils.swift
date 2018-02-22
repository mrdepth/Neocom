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

func load<T: Codable>(_ url: URL, type: T.Type = T.self) -> Future<T> {
	let future = Future<T>()
	future.work = DispatchWorkItem { [weak future] in
		do {
//			print("\(url.path)")
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
	fileprivate var work: DispatchWorkItem?
	fileprivate var value: T!
	fileprivate var error: Error?
	
	func get() throws -> T {
		work?.wait()
		if let error = error {
			throw error
		}
		return value
	}
}

enum NCDBDgmppItemCategoryID: Int32 {
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
}

enum NCDBDgmAttributeID: Int {
	case metaGroup = 1692
	case metaLevel = 633
}

enum NCDBRegionID: Int {
	case whSpace = 11000000
}

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
		let scanner = Scanner(string: string)
		var rgba: UInt32 = 0
		if scanner.scanHexInt32(&rgba) {
			self.init(number:UInt(rgba))
		}
		else {
			let key = string.capitalized
			for colorList in NSColorList.availableColorLists {
				
				guard let color = colorList.color(withKey: NSColor.Name(key)) else {continue}
				self.init(cgColor: color.cgColor)
				return
			}
		}
		return nil
	}
}

extension NSAttributedString {
	convenience init(html: String?) {
		var html = html ?? ""
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
			replace.addAttribute(NSAttributedStringKey(rawValue: "UIFontDescriptorSymbolicTraits"), value: CTFontSymbolicTraits.boldTrait.rawValue, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.range(at: 0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "<i[^>]*>(.*?)</i>", options: options)
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.range(at: 1)).mutableCopy() as! NSMutableAttributedString
			replace.addAttribute(NSAttributedStringKey(rawValue: "UIFontDescriptorSymbolicTraits"), value: CTFontSymbolicTraits.italicTrait.rawValue, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.range(at: 0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "<u[^>]*>(.*?)</u>", options: options)
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let replace = s.attributedSubstring(from: result.range(at: 1)).mutableCopy() as! NSMutableAttributedString
			replace.addAttribute(NSAttributedStringKey.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: NSMakeRange(0, replace.length))
			s.replaceCharacters(in: result.range(at: 0), with: replace)
		}
		
		expression = try! NSRegularExpression(pattern: "<(color|font)[^>]*=[\"']?(.*?)[\"']?\\s*?>(.*?)</(color|font)>", options: [.caseInsensitive])
		
		for result in expression.matches(in: s.string, options: [], range: NSMakeRange(0, s.length)).reversed() {
			let key = s.attributedSubstring(from: result.range(at: 2)).string
			let replace = s.attributedSubstring(from: result.range(at: 3)).mutableCopy() as! NSMutableAttributedString
			if let color = NSColor(string: key) {
				replace.addAttribute(NSAttributedStringKey.foregroundColor, value: color, range: NSMakeRange(0, replace.length))
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



