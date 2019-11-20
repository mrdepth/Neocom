//
//  ImplantSetDescription.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/02/2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation

@objc(ImplantSetDescription)
public class ImplantSetDescription: NSObject, NSSecureCoding {
	public var implantIDs: [Int]?
	public var boosterIDs: [Int]?
	
	public enum CodingKeys: String, CodingKey {
		case implantIDs
		case boosterIDs
	}

	public static var supportsSecureCoding: Bool { return true }
	
	public override init() {
		super.init()
	}

	public func encode(with aCoder: NSCoder) {
		aCoder.encode(implantIDs, forKey: CodingKeys.implantIDs.stringValue)
		aCoder.encode(boosterIDs, forKey: CodingKeys.boosterIDs.stringValue)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		implantIDs = aDecoder.decodeObject(of: [NSArray.self, NSNumber.self], forKey: CodingKeys.implantIDs.stringValue) as? [Int]
		boosterIDs = aDecoder.decodeObject(of: [NSArray.self, NSNumber.self], forKey: CodingKeys.boosterIDs.stringValue) as? [Int]
	}
	

	public override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? ImplantSetDescription else {return false}
		return implantIDs == other.implantIDs &&
			boosterIDs == other.boosterIDs
	}

}
