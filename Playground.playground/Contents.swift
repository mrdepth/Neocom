//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport
import CoreData


class C: NSObject, NSCoding, Codable {
	var a: Int = 0
	
	init(_ a: Int) {
		self.a = a
	}
	
	required init?(coder aDecoder: NSCoder) {
		(aDecoder as? NSKeyedUnarchiver)?.decodeDecodable(type(of: self).self, forKey: "self")
	}
	
	func encode(with aCoder: NSCoder) {
//		aCoder.encode(a, forKey: "a")
		try? (aCoder as? NSKeyedArchiver)?.encodeEncodable(self, forKey: "self")
	}
}

String(data: (try! PropertyListEncoder().encode(C(10))), encoding: .utf8)

let d = NSKeyedArchiver.archivedData(withRootObject: C(10))

NSKeyedUnarchiver.unarchiveObject(with: d)


