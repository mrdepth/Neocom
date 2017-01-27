//
//  NCLoadout.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingLoadoutItem: NSObject, NSCoding {
	let typeID: Int
	let count: Int
	
	required init?(coder aDecoder: NSCoder) {
		typeID = aDecoder.decodeInteger(forKey: "typeID")
		count = aDecoder.decodeObject(forKey: "count") as? Int ?? 1
		super.init()
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(typeID, forKey: "typeID")
		if count != 1 {
			aCoder.encode(count, forKey: "count")
		}
	}
	
	public static func ==(lhs: NCFittingLoadoutItem, rhs: NCFittingLoadoutItem) -> Bool {
		return lhs.hashValue == rhs.hashValue
	}
	
	override var hashValue: Int {
		return [typeID, count].hashValue
	}
}

class NCFittingLoadoutModule: NCFittingLoadoutItem {
	let state: NCFittingModuleState
	let charge: NCFittingLoadoutItem?
	
	required init?(coder aDecoder: NSCoder) {
		state = NCFittingModuleState(rawValue: aDecoder.decodeInteger(forKey: "state")) ?? .unknown
		charge = aDecoder.decodeObject(forKey: "charge") as? NCFittingLoadoutItem
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		aCoder.encode(state.rawValue, forKey: "state")
		aCoder.encode(charge, forKey: "charge")
	}

	override var hashValue: Int {
		return [typeID, count, state.rawValue, charge?.typeID ?? 0].hashValue
	}
}

class NCFittingLoadoutDrone: NCFittingLoadoutItem {
	let isActive: Bool
	
	required init?(coder aDecoder: NSCoder) {
		isActive = aDecoder.decodeObject(forKey: "isActive") as? Bool ?? true
		super.init(coder: aDecoder)
	}
	
	override func encode(with aCoder: NSCoder) {
		super.encode(with: aCoder)
		if !isActive {
			aCoder.encode(isActive, forKey: "isActive")
		}
	}

	override var hashValue: Int {
		return [typeID, count, isActive ? 1 : 0].hashValue
	}
}


public class NCFittingLoadout: NSObject, NSCoding {
	var modules: [NCFittingModuleSlot: [NCFittingLoadoutModule]]?
	var drones: [NCFittingLoadoutDrone]?
	var cargo: [NCFittingLoadoutItem]?
	var implants: [NCFittingLoadoutItem]?
	var boosters: [NCFittingLoadoutItem]?
	
	override init() {
		super.init()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		modules = [NCFittingModuleSlot: [NCFittingLoadoutModule]]()
		for (key, value) in aDecoder.decodeObject(forKey: "modules") as? [Int: [NCFittingLoadoutModule]] ?? [:] {
			guard let key = NCFittingModuleSlot(rawValue: key) else {continue}
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


extension NCFittingCharacter {
	var loadout: NCFittingLoadout {
		get {
			return NCFittingLoadout()
		}
		set {
			let ship = self.ship!
			for implant in loadout.implants ?? [] {
				addImplant(typeID: implant.typeID)
			}
			for booster in loadout.boosters ?? [] {
				addBooster(typeID: booster.typeID)
			}
			for drone in loadout.drones ?? [] {
				for _ in 0..<drone.count {
					ship.addDrone(typeID: drone.typeID)
				}
			}
			for (_, modules) in loadout.modules?.sorted(by: { $0.key.rawValue > $1.key.rawValue }) ?? [] {
				for module in modules {
					for _ in 0..<module.count {
						guard let m = ship.addModule(typeID: module.typeID) else {continue}
						m.preferredState = module.state
						if let charge = module.charge {
							m.charge = NCFittingCharge(typeID: charge.typeID)
						}
					}
				}
			}
		}
	}
}

extension NCFittingModuleSlot {
	var image: UIImage? {
		switch self {
		case .hi:
			return #imageLiteral(resourceName: "slotHigh")
		case .med:
			return #imageLiteral(resourceName: "slotMed")
		case .low:
			return #imageLiteral(resourceName: "slotLow")
		case .rig:
			return #imageLiteral(resourceName: "slotRig")
		case .subsystem:
			return #imageLiteral(resourceName: "slotSubsystem")
		case .service:
			return #imageLiteral(resourceName: "slotService")
		case .mode:
			return #imageLiteral(resourceName: "slotSubsystem")
		default:
			return nil
		}
	}
	
	var title: String? {
		switch self {
		case .hi:
			return NSLocalizedString("Hi Slot", comment: "")
		case .med:
			return NSLocalizedString("Med Slot", comment: "")
		case .low:
			return NSLocalizedString("Low Slot", comment: "")
		case .rig:
			return NSLocalizedString("Rig Slot", comment: "")
		case .subsystem:
			return NSLocalizedString("Subsystems", comment: "")
		case .service:
			return NSLocalizedString("Services", comment: "")
		case .mode:
			return NSLocalizedString("Mode", comment: "")
		default:
			return nil
		}
	}
}

extension NCFittingModuleState {
	var image: UIImage? {
		switch self {
		case .offline:
			return #imageLiteral(resourceName: "offline")
		case .online:
			return #imageLiteral(resourceName: "online")
		case .active:
			return #imageLiteral(resourceName: "active")
		case .overloaded:
			return #imageLiteral(resourceName: "overheated")
		default:
			return nil
		}
	}
	
	var title: String? {
		switch self {
		case .offline:
			return NSLocalizedString("Offline", comment: "")
		case .online:
			return NSLocalizedString("Online", comment: "")
		case .active:
			return NSLocalizedString("Active", comment: "")
		case .overloaded:
			return NSLocalizedString("Overheated", comment: "")
		default:
			return nil
		}
	}
}

extension NCFittingScanType {
	var image: UIImage? {
		switch self {
		case .gravimetric:
			return #imageLiteral(resourceName: "gravimetric")
		case .magnetometric:
			return #imageLiteral(resourceName: "magnetometric")
		case .ladar:
			return #imageLiteral(resourceName: "ladar")
		case .radar:
			return #imageLiteral(resourceName: "radar")
		case .multispectral:
			return #imageLiteral(resourceName: "multispectral")
		}
	}
	
	var title: String? {
		switch self {
		case .gravimetric:
			return NSLocalizedString("Gravimetric", comment: "")
		case .magnetometric:
			return NSLocalizedString("Magnetometric", comment: "")
		case .ladar:
			return NSLocalizedString("Ladar", comment: "")
		case .radar:
			return NSLocalizedString("Radar", comment: "")
		case .multispectral:
			return NSLocalizedString("Multispectral", comment: "")
		}
	}
}
