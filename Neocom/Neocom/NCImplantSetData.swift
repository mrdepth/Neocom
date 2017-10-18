//
//  NCImplantSetData.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

public class NCImplantSetData: NSObject, NSSecureCoding {
	var implantIDs: [Int]?
	var boosterIDs: [Int]?
	
	public override init() {
		super.init()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		implantIDs = aDecoder.decodeObject(forKey: "implantIDs") as? [Int]
		boosterIDs = aDecoder.decodeObject(forKey: "boosterIDs") as? [Int]
		super.init()
	}
	
	public func encode(with aCoder: NSCoder) {
		aCoder.encode(implantIDs, forKey: "implantIDs")
		aCoder.encode(boosterIDs, forKey: "boosterIDs")
	}
	
	public static var supportsSecureCoding: Bool {
		return true
	}
}
