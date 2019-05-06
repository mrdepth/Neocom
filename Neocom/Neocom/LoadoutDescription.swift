//
//  LoadoutDescription.swift
//  Neocom
//
//  Created by Artem Shimanski on 27/01/2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp

@objc(LoadoutDescription)
public class LoadoutDescription: NSObject, NSSecureCoding {
	public var modules: [DGMModule.Slot: [Item.Module]]?
	public var drones: [Item.Drone]?
	public var cargo: [Item]?
	public var implants: [Item]?
	public var boosters: [Item]?
	
	public static var supportsSecureCoding: Bool { return true }
	
	public enum CodingKeys: String, CodingKey {
		case modules
		case drones
		case cargo
		case implants
		case boosters
	}
	
	public override init() {
		super.init()
	}

	public required init?(coder aDecoder: NSCoder) {
		modules = (aDecoder.decodeObject(of: [Item.Module.self, NSDictionary.self, NSArray.self], forKey: CodingKeys.modules.stringValue) as? [Int: [Item.Module]]).map { dic -> [DGMModule.Slot: [Item.Module]] in
			let pairs = dic.compactMap { (key, value) -> (DGMModule.Slot, [Item.Module])? in
				guard let key = DGMModule.Slot(rawValue: key) else {return nil}
				return (key, value)
			}
			return Dictionary(pairs, uniquingKeysWith: { a, _ in a})
		}
		drones = aDecoder.decodeObject(of: [Item.Drone.self, NSArray.self], forKey: CodingKeys.drones.stringValue) as? [Item.Drone]
		cargo = aDecoder.decodeObject(of: [Item.self, NSArray.self], forKey: CodingKeys.cargo.stringValue) as? [Item]
		implants = aDecoder.decodeObject(of: [Item.self, NSArray.self], forKey: CodingKeys.implants.stringValue) as? [Item]
		boosters = aDecoder.decodeObject(of: [Item.self, NSArray.self], forKey: CodingKeys.boosters.stringValue) as? [Item]
		super.init()
	}
	
	public func encode(with aCoder: NSCoder) {
		if let modules = modules, !modules.isEmpty {
			let dic = Dictionary(modules.map {($0.key.rawValue, $0.value)}, uniquingKeysWith: {a, _ in a})
			aCoder.encode(dic, forKey: CodingKeys.modules.stringValue)
		}
		if drones?.isEmpty == false {
			aCoder.encode(drones, forKey: CodingKeys.drones.stringValue)
		}
		if cargo?.isEmpty == false {
			aCoder.encode(cargo, forKey: CodingKeys.cargo.stringValue)
		}
		if implants?.isEmpty == false {
			aCoder.encode(implants, forKey: CodingKeys.implants.stringValue)
		}
		if boosters?.isEmpty == false {
			aCoder.encode(boosters, forKey: CodingKeys.boosters.stringValue)
		}
	}
	
	public override func isEqual(_ object: Any?) -> Bool {
		guard let other = object as? LoadoutDescription else {return false}
		return modules == other.modules &&
			drones == other.drones &&
			cargo == other.cargo &&
			implants == other.implants &&
			boosters == other.boosters
	}
}



extension LoadoutDescription {
	
	@objc(LoadoutDescriptionItem)
	public class Item: NSObject, NSSecureCoding {
		public let typeID: Int
		public var count: Int
		public let identifier: Int?

		public class var supportsSecureCoding: Bool { return true }
		
		public enum CodingKeys: String, CodingKey {
			case typeID
			case count
			case identifier
		}

		
		public convenience init(type: DGMType, count: Int = 1) {
			self.init(typeID: type.typeID, count: count, identifier: type.identifier)
		}
		
		public init(typeID: Int, count: Int, identifier: Int? = nil) {
			self.typeID = typeID
			self.count = count
			self.identifier = identifier
			super.init()
		}
		
		public required init?(coder aDecoder: NSCoder) {
			
			typeID = aDecoder.decodeInteger(forKey: CodingKeys.typeID.stringValue)
			count = aDecoder.containsValue(forKey: CodingKeys.count.stringValue) ? aDecoder.decodeInteger(forKey: CodingKeys.count.stringValue) : 1
			if aDecoder.containsValue(forKey: CodingKeys.identifier.stringValue) {
				if let s = aDecoder.decodeObject(of: NSString.self, forKey: CodingKeys.identifier.stringValue) as String? {
					identifier = Int(s) ?? s.hashValue
				}
				else {
					identifier = aDecoder.decodeObject(of: NSNumber.self, forKey: CodingKeys.identifier.stringValue)?.intValue
//					identifier = aDecoder.decodeInteger(forKey: CodingKeys.identifier.stringValue)
				}
			}
			else {
				identifier = nil
			}
			super.init()
		}
		
		public func encode(with aCoder: NSCoder) {
			aCoder.encode(typeID, forKey: CodingKeys.typeID.stringValue)
			if count != 1 {
				aCoder.encode(count, forKey: CodingKeys.count.stringValue)
			}
			if let identifier = identifier {
				aCoder.encode(identifier, forKey: CodingKeys.identifier.stringValue)
			}
		}
		
		public override func isEqual(_ object: Any?) -> Bool {
			guard let other = object as? Item else {return false}
			guard type(of: self) == type(of: other) else {return false}
			return typeID == other.typeID && count == other.count
		}
		
		public override var hash: Int {
			var hasher = Hasher()
			hash(&hasher)
			return hasher.finalize()
		}
		
		fileprivate func hash(_ hasher: inout Hasher) {
			hasher.combine(typeID)
			hasher.combine(count)
		}
		
	}
}


extension LoadoutDescription.Item {
	@objc(LoadoutDescriptionModule)
	public class Module: LoadoutDescription.Item {
		public let state: DGMModule.State
		public let charge: LoadoutDescription.Item?
		public let socket: Int

		public enum CodingKeys: String, CodingKey {
			case state
			case charge
			case socket
		}
		
		public override class var supportsSecureCoding: Bool { return true }
		
		public convenience init(module: DGMModule) {
			self.init(typeID: module.typeID,
					  count: 1,
					  identifier: module.identifier,
					  state: module.state,
					  charge: module.charge.map{LoadoutDescription.Item(type: $0, count: max(module.charges, 1))},
					  socket: module.socket)
		}
		
		public init(typeID: Int, count: Int, identifier: Int?, state: DGMModule.State = .active, charge: LoadoutDescription.Item? = nil, socket: Int = -1) {
			self.state = state
			self.charge = charge
			self.socket = socket
			super.init(typeID: typeID, count: count, identifier: identifier)
		}

		public required init?(coder aDecoder: NSCoder) {
			state = DGMModule.State(rawValue: aDecoder.decodeInteger(forKey: CodingKeys.state.stringValue)) ?? .unknown
			charge = aDecoder.decodeObject(of: LoadoutDescription.Item.self, forKey: CodingKeys.charge.stringValue)
			socket = aDecoder.containsValue(forKey: CodingKeys.socket.stringValue) ? aDecoder.decodeInteger(forKey: CodingKeys.socket.stringValue) : -1
			super.init(coder: aDecoder)
		}
		
		public override func encode(with aCoder: NSCoder) {
			aCoder.encode(state.rawValue, forKey: CodingKeys.state.stringValue)
			aCoder.encode(charge, forKey: CodingKeys.charge.stringValue)
			aCoder.encode(socket, forKey: CodingKeys.socket.stringValue)
			super.encode(with: aCoder)
		}
		
		public override func isEqual(_ object: Any?) -> Bool {
			guard super.isEqual(object) else {return false}
			guard let other = object as? Module else {return false}
			return state == other.state && charge == other.charge && socket == other.socket
		}
		
		fileprivate override func hash(_ hasher: inout Hasher) {
			super.hash(&hasher)
			hasher.combine(state)
			hasher.combine(charge)
			hasher.combine(socket)
		}
	}
	
	@objc(LoadoutDescriptionDrone)
	public class Drone: LoadoutDescription.Item {
		public let isActive: Bool
		public let isKamikaze: Bool
		public let squadronTag: Int
		
		public enum CodingKeys: String, CodingKey {
			case isActive
			case isKamikaze
			case squadronTag
		}

		public override class var supportsSecureCoding: Bool { return true }
		
		public convenience init(drone: DGMDrone) {
			self.init(typeID: drone.typeID, count: 1, identifier: drone.identifier, isActive: drone.isActive, isKamikaze: drone.isKamikaze, squadronTag: drone.squadronTag)
		}

		public init(typeID: Int, count: Int, identifier: Int?, isActive: Bool = true, isKamikaze: Bool = false, squadronTag: Int = -1) {
			self.isActive = isActive
			self.squadronTag = squadronTag
			self.isKamikaze = isKamikaze
			super.init(typeID: typeID, count: count, identifier: identifier)
		}
		
		public required init?(coder aDecoder: NSCoder) {
			isActive = aDecoder.containsValue(forKey: CodingKeys.isActive.stringValue) ? aDecoder.decodeBool(forKey: CodingKeys.isActive.stringValue) : true
			isKamikaze = aDecoder.containsValue(forKey: CodingKeys.isKamikaze.stringValue) ? aDecoder.decodeBool(forKey: CodingKeys.isKamikaze.stringValue) : false
			squadronTag = aDecoder.containsValue(forKey: CodingKeys.squadronTag.stringValue) ? aDecoder.decodeInteger(forKey: CodingKeys.squadronTag.stringValue) : -1
			super.init(coder: aDecoder)
		}
		
		public override func encode(with aCoder: NSCoder) {
			if !isActive {
				aCoder.encode(isActive, forKey: CodingKeys.isActive.stringValue)
			}
			if !isKamikaze {
				aCoder.encode(isKamikaze, forKey: CodingKeys.isKamikaze.stringValue)
			}
			
			aCoder.encode(squadronTag, forKey: CodingKeys.squadronTag.stringValue)
			super.encode(with: aCoder)
		}
		
		public override func isEqual(_ object: Any?) -> Bool {
			guard super.isEqual(object) else {return false}
			guard let other = object as? Drone else {return false}
			return isActive == other.isActive && isKamikaze == other.isKamikaze && squadronTag == other.squadronTag
		}

		
		fileprivate override func hash(_ hasher: inout Hasher) {
			super.hash(&hasher)
			hasher.combine(isActive)
			hasher.combine(isKamikaze)
			hasher.combine(squadronTag)
		}
	}
}
