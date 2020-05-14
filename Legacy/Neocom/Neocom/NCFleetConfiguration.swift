//
//  NCFleetConfiguration.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

public class NCFleetConfiguration: NSObject, NSCoding {
	var pilots: [Int: String]?
	var links: [Int: Int]?
	
	override init() {
		super.init()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		if let d = aDecoder.decodeObject(forKey: "pilots") as? [String: String] {
			pilots = Dictionary(d.map{ (Int($0) ?? $0.hashValue, $1) },
								uniquingKeysWith: { (first, _) in first})
		}
		else {
			pilots = aDecoder.decodeObject(forKey: "pilots") as? [Int: String]
		}
		if let d = aDecoder.decodeObject(forKey: "links") as? [String: String] {
			links = Dictionary(d.map{ (Int($0) ?? $0.hashValue, Int($1) ?? $1.hashValue) },
								uniquingKeysWith: { (first, _) in first})
		}
		else {
			links = aDecoder.decodeObject(forKey: "links") as? [Int: Int]
		}
		super.init()
	}
	
	public func encode(with aCoder: NSCoder) {
		aCoder.encode(pilots, forKey: "pilots")
		aCoder.encode(links, forKey: "links")
	}
}
