//
//  NCLoadoutActivityItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

enum NCLoadoutRepresentation {
	case dna([(typeID: Int, data: NCFittingLoadout, name: String)])
	case dnaURL([(typeID: Int, data: NCFittingLoadout, name: String)])
	case xml([(typeID: Int, data: NCFittingLoadout, name: String)])
	case httpURL([(typeID: Int, data: NCFittingLoadout, name: String)])
	case eft([(typeID: Int, data: NCFittingLoadout, name: String)])
	case esi([(typeID: Int, data: NCFittingLoadout, name: String)])
	
	var value: Any {
		switch self {
		case let .dna(loadouts):
			return loadouts.map{dnaRepresentation($0)}
		case let .dnaURL(loadouts):
			return loadouts.flatMap{URL(string: "fitting:" + dnaRepresentation($0))}
		case let .xml(loadouts):
			return "<?xml version=\"1.0\" ?>\n<fittings>\n\(loadouts.map {xmlRepresentation($0)}.joined(separator: "\n"))\n</fittings>"
		case let .httpURL(loadouts):
			return loadouts.flatMap{URL(string: "http://neocom.by/api/fitting?dna=" + dnaRepresentation($0))}
		case let .eft(loadouts):
			return loadouts.map{eftRepresentation($0)}
		default:
			break
		}
		return 1
	}
	
	private func dnaRepresentation(_ loadout: (typeID: Int, data: NCFittingLoadout, name: String)) -> String {
		let slots: [NCFittingModuleSlot] = [.subsystem, .hi, .med, .low, .rig]
		var arrays = [NSCountedSet]()
		let charges = NSCountedSet()
		let drones = NSCountedSet()
		
		for slot in slots {
			let array = NSCountedSet()
			for module in loadout.data.modules?[slot] ?? [] {
				for _ in 0..<module.count {
					array.add(module.typeID)
					if let charge = module.charge {
						charges.add(charge.typeID)
					}
				}
			}
			arrays.append(array)
		}
		
		for drone in loadout.data.drones ?? [] {
			for _ in 0..<drone.count {
				drones.add(drone.typeID)
			}
		}
		
		arrays.append(drones)
		arrays.append(charges)
		
		var dna = "\(loadout.typeID):"
		for array in arrays {
			for typeID in array.allObjects as! [Int] {
				dna += "\(typeID);\(array.count(for: typeID)):"
			}
		}
		dna += ":"
		
		return dna
	}
	
	private func xmlRepresentation(_ loadout: (typeID: Int, data: NCFittingLoadout, name: String)) -> String {
		var xml = ""
		NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext in
			let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
			guard let type = invTypes[loadout.typeID]?.typeName else {return}
			xml += "<fitting name=\"\(loadout.name)\">\n<description value=\"\(NSLocalizedString("Created with Neocom on iOS", comment: ""))\"/>\n<shipType value=\"\(type)\"/>\n"
			
			let slots: [NCFittingModuleSlot] = [.hi, .med, .low, .rig, .subsystem]
			for slot in slots {
				for (i, module) in (loadout.data.modules?[slot] ?? []).enumerated() {
					guard let type = invTypes[module.typeID]?.typeName else {continue}
					guard let slot = slot.title?.lowercased() else {continue}
					xml += "<hardware slot=\"\(slot) \(i)\" type=\"\(type)\"/>\n"
				}
			}
			
			for drone in loadout.data.drones ?? [] {
				guard let type = invTypes[drone.typeID]?.typeName else {continue}
				guard drone.count > 0 else {continue}
				xml += "<hardware slot=\"drone bay\" qty=\"\(drone.count)\" type=\"\(type)\"/>\n"
			}
			xml += "</fitting>\n"
		}
		return xml
	}
	
	private func eftRepresentation(_ loadout: (typeID: Int, data: NCFittingLoadout, name: String)) -> String {
		var eft = ""
		NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext in
			let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
			guard let type = invTypes[loadout.typeID]?.typeName else {return}
			eft += "[\(type), \(loadout.name)]\n"
			
			let slots: [NCFittingModuleSlot] = [.hi, .med, .low, .rig, .subsystem]
			for slot in slots {
				guard let modules = loadout.data.modules?[slot], modules.count > 0 else {continue}
				for module in modules {
					guard let type = invTypes[module.typeID]?.typeName else {continue}
					eft += "\(type)"
					if let chargeID = module.charge?.typeID, let charge = invTypes[chargeID]?.typeName {
						eft += ", \(charge)"
					}
					eft += "\n"
				}
				eft += "\n"
			}

			for drone in loadout.data.drones ?? [] {
				guard let type = invTypes[drone.typeID]?.typeName else {continue}
				eft += "\(type) x\(drone.count)\n"
			}
		}
		return eft
	}
}

class NCLoadoutActivityItem: UIActivityItemProvider {
	
//	let loadout: NCFittingLoadout
	let representation: NCLoadoutRepresentation
	
	init(representation: NCLoadoutRepresentation) {
		self.representation = representation
//		let type = NCDatabase.sharedDatabase?.invTypes[typeID]
//		self.loadout = loadout
//		let image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image ?? #imageLiteral(resourceName: "priceShip")
//		super.init(placeholderItem: loadout)
		let value = (representation.value as? [Any])?.first ?? representation
		super.init(placeholderItem: value)
	}
	
	override var item: Any {
		let value = (representation as? [Any])?.first ?? representation
//		return representation.value
//		return loadout
//		/return ""
	}
	
	
}

extension NCFittingCharacter: UIActivityItemSource {
	
	public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
//		return URL(string: "http://neocom.by")!
		return ""
	}
	
	public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
//		return URL(string: "http://neocom.by")!
		return "asdfasdfsdf"
	}
	
	public func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
		return "asdf"
	}
	
	public func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivityType?, suggestedSize size: CGSize) -> UIImage? {
		var image: UIImage?
		engine?.performBlockAndWait {
			guard let ship = self.ship else {return}
			image = NCDatabase.sharedDatabase?.invTypes[ship.typeID]?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		}
		return image ?? #imageLiteral(resourceName: "priceShip")
	}


}
