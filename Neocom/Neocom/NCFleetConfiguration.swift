//
//  NCFleetConfiguration.swift
//  Neocom
//
//  Created by Artem Shimanski on 15.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

public class NCFleetConfiguration: NSObject, NSCoding {
	var pilots: [String: String]?
	var links: [String: String]?
	
	override init() {
		super.init()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		pilots = aDecoder.decodeObject(forKey: "pilots") as? [String: String]
		links = aDecoder.decodeObject(forKey: "links") as? [String: String]
		super.init()
	}
	
	public func encode(with aCoder: NSCoder) {
		aCoder.encode(pilots, forKey: "pilots")
		aCoder.encode(links, forKey: "links")
	}
}
