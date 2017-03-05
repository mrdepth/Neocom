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
	var fleetBooster: String?
	var squadBooster: String?
	var wingBooster: String?
	
	override init() {
		super.init()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		pilots = aDecoder.decodeObject(forKey: "pilots") as? [String: String]
		links = aDecoder.decodeObject(forKey: "links") as? [String: String]
		fleetBooster = aDecoder.decodeObject(forKey: "fleetBooster") as? String
		squadBooster = aDecoder.decodeObject(forKey: "squadBooster") as? String
		wingBooster = aDecoder.decodeObject(forKey: "wingBooster") as? String
		super.init()
	}
	
	public func encode(with aCoder: NSCoder) {
		aCoder.encode(pilots, forKey: "pilots")
		aCoder.encode(links, forKey: "links")
		aCoder.encode(fleetBooster, forKey: "fleetBooster")
		aCoder.encode(squadBooster, forKey: "squadBooster")
		aCoder.encode(wingBooster, forKey: "wingBooster")
	}
}
