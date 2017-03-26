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
	
	let representation: NCLoadoutRepresentation
	let value: Any?
	let data: String?
	
	init(representation: NCLoadoutRepresentation) {
		self.representation = representation
		var value = representation.value
		var data: String?
		
		switch representation {
		case .dna:
			value = (value as? [String])?.joined(separator: "\n") ?? value
		case .dnaURL, .httpURL:
			value = (value as? [URL])?.map({$0.absoluteString}).joined(separator: "\n") ?? value
		case let .eft(loadouts):
			guard let loadout = loadouts.first else {break}
			let typeName = NCDatabase.sharedDatabase?.invTypes[loadout.typeID]?.typeName ?? "\(loadout.typeID)"
			let name = loadout.name.isEmpty ? "Unnamed" : loadout.name
			
			data = (value as? [String])?.first
			value = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(typeName) - \(name).cfg")
		case let .xml(loadouts):
			let fileName: String
			if loadouts.count > 1 {
				fileName = "Loadouts.xml"
			}
			else {
				guard let loadout = loadouts.first else {break}
				let typeName = NCDatabase.sharedDatabase?.invTypes[loadout.typeID]?.typeName ?? "\(loadout.typeID)"
				let name = loadout.name.isEmpty ? "Unnamed" : loadout.name
				
				fileName = "\(typeName) - \(name).xml"
			}
			
			data = value as? String
			value = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
		default:
			break
		}
		self.data = data
		self.value = value
		super.init(placeholderItem: value)
	}
	
	override var item: Any {
		if let data = data, let url = value as? URL {
			try? data.write(to: url, atomically: true, encoding: .utf8)
			return url
		}
		else {
			return value ?? ""
		}
	}
	
	deinit {
		if let url = value as? URL {
			try? FileManager.default.removeItem(at: url)
		}
	}
}
