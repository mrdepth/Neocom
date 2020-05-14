//
//  NCLoadout.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI
import Dgmpp

class NCFittingLoadoutItem: NSObject, NSSecureCoding {
	let typeID: Int
	var count: Int
	let identifier: Int?
	
	public static var supportsSecureCoding: Bool {
		return true
	}
	
	init(type: DGMType, count: Int = 1) {
		self.typeID = type.typeID
		self.count = count
		self.identifier = type.identifier
		super.init()
	}
	
	init(typeID: Int, count: Int, identifier: Int? = nil) {
		self.typeID = typeID
		self.count = count
		self.identifier = identifier
		super.init()
	}
	
	required init?(coder aDecoder: NSCoder) {
		typeID = aDecoder.decodeInteger(forKey: "typeID")
		count = aDecoder.containsValue(forKey: "count") ? aDecoder.decodeInteger(forKey: "count") : 1
		if let s = (aDecoder.decodeObject(forKey: "identifier") as? String) {
			identifier = Int(s) ?? s.hashValue
		}
		else if let n = (aDecoder.decodeObject(forKey: "identifier") as? NSNumber) {
			identifier = n.intValue
		}
		else {
			identifier = nil
		}
		super.init()
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(typeID, forKey: "typeID")
		if count != 1 {
			aCoder.encode(count, forKey: "count")
		}
		aCoder.encode(identifier, forKey: "identifier")
	}
	
	public static func ==(lhs: NCFittingLoadoutItem, rhs: NCFittingLoadoutItem) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
	
	override var hash: Int {
		return [typeID, count].hashValue
	}
}

class NCFittingLoadoutModule: NCFittingLoadoutItem {
	let state: DGMModule.State
	let charge: NCFittingLoadoutItem?
	let socket: Int
	
	init(module: DGMModule) {
		state = module.preferredState
		if let charge = module.charge {
			self.charge = NCFittingLoadoutItem(type: charge, count: max(module.charges, 1))
		}
		else {
			self.charge = nil
		}
		socket = module.socket
		super.init(type: module)
	}
	
	init(typeID: Int, count: Int, identifier: Int?, state: DGMModule.State = .active, charge: NCFittingLoadoutItem? = nil, socket: Int = -1) {
		self.state = state
		self.charge = charge
		self.socket = socket
		super.init(typeID: typeID, count: count, identifier: identifier)
	}
	
	required init?(coder aDecoder: NSCoder) {
		state = DGMModule.State(rawValue: aDecoder.decodeInteger(forKey: "state")) ?? .unknown
		charge = aDecoder.decodeObject(forKey: "charge") as? NCFittingLoadoutItem
		socket = aDecoder.containsValue(forKey: "socket") ? aDecoder.decodeInteger(forKey: "socket") : -1
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(state.rawValue, forKey: "state")
		aCoder.encode(charge, forKey: "charge")
		aCoder.encode(socket, forKey: "socket")
	}

	override var hash: Int {
		return [typeID, count, state.rawValue, charge?.typeID ?? 0].hashValue
	}
}

class NCFittingLoadoutDrone: NCFittingLoadoutItem {
	let isActive: Bool
	let isKamikaze: Bool
	let squadronTag: Int
	
	init(typeID: Int, count: Int, identifier: Int?, isActive: Bool = true, squadronTag: Int = -1) {
		self.isActive = isActive
		self.squadronTag = squadronTag
		self.isKamikaze = false
		super.init(typeID: typeID, count: count, identifier: identifier)
	}
	
	init(drone: DGMDrone) {
		self.isActive = drone.isActive
		self.isKamikaze = drone.isKamikaze
		self.squadronTag = drone.squadronTag
		super.init(type: drone)
	}

	required init?(coder aDecoder: NSCoder) {
		isActive = aDecoder.containsValue(forKey: "isActive") ? aDecoder.decodeBool(forKey: "isActive") : true
		isKamikaze = aDecoder.containsValue(forKey: "isKamikaze") ? aDecoder.decodeBool(forKey: "isKamikaze") : false
		squadronTag = aDecoder.containsValue(forKey: "squadronTag") ? aDecoder.decodeInteger(forKey: "squadronTag") : -1
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		if !isActive {
			aCoder.encode(isActive, forKey: "isActive")
		}
		if !isKamikaze {
			aCoder.encode(isKamikaze, forKey: "isKamikaze")
		}

		aCoder.encode(squadronTag, forKey: "squadronTag")
	}

	override var hash: Int {
		return [typeID, count, isActive ? 1 : 0].hashValue
	}
}

public class NCFittingLoadout: NSObject, NSSecureCoding {
	var modules: [DGMModule.Slot: [NCFittingLoadoutModule]]?
	var drones: [NCFittingLoadoutDrone]?
	var cargo: [NCFittingLoadoutItem]?
	var implants: [NCFittingLoadoutItem]?
	var boosters: [NCFittingLoadoutItem]?
	
	override init() {
		super.init()
	}
	
	public static var supportsSecureCoding: Bool {
		return true
	}

	
	public required init?(coder aDecoder: NSCoder) {
		modules = [DGMModule.Slot: [NCFittingLoadoutModule]]()
		for (key, value) in aDecoder.decodeObject(forKey: "modules") as? [Int: [NCFittingLoadoutModule]] ?? [:] {
			guard let key = DGMModule.Slot(rawValue: key) else {continue}
			modules?[key] = value
		}
		
		drones = aDecoder.decodeObject(forKey: "drones") as? [NCFittingLoadoutDrone]
		cargo = aDecoder.decodeObject(forKey: "cargo") as? [NCFittingLoadoutItem]
		implants = aDecoder.decodeObject(forKey: "implants") as? [NCFittingLoadoutItem]
		boosters = aDecoder.decodeObject(forKey: "boosters") as? [NCFittingLoadoutItem]
		super.init()
	}
	
	public func encode(with aCoder: NSCoder) {
		var dic = [Int: [NCFittingLoadoutModule]]()
		for (key, value) in modules ?? [:] {
			dic[key.rawValue] = value
		}
		
		aCoder.encode(dic, forKey:"modules")

		if drones?.count ?? 0 > 0 {
			aCoder.encode(drones, forKey: "drones")
		}
		if cargo?.count ?? 0 > 0 {
			aCoder.encode(cargo, forKey: "cargo")
		}
		if implants?.count ?? 0 > 0 {
			aCoder.encode(implants, forKey: "implants")
		}
		if boosters?.count ?? 0 > 0 {
			aCoder.encode(boosters, forKey: "boosters")
		}
	}
}


