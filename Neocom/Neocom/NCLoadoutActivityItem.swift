//
//  NCLoadoutActivityItem.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

enum NCLoadoutRepresentation {
	case dna([(typeID: Int, data: NCFittingLoadout, name: String)])
	case dnaURL([(typeID: Int, data: NCFittingLoadout, name: String)])
	case xml([(typeID: Int, data: NCFittingLoadout, name: String)])
	case httpURL([(typeID: Int, data: NCFittingLoadout, name: String)])
	case eft([(typeID: Int, data: NCFittingLoadout, name: String)])
	case esi([(typeID: Int, data: NCFittingLoadout, name: String)])
	case inGame([(typeID: Int, data: NCFittingLoadout, name: String)])
	
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
		case let .inGame(loadouts):
			return loadouts.map{inGameRepresentation($0)}
		default:
			break
		}
		return 1
	}
	
	var loadouts: [(typeID: Int, data: NCFittingLoadout, name: String)] {
		switch self {
		case let .dna(value):
			return value
		case let .dnaURL(value):
			return value
		case let .xml(value):
			return value
		case let .httpURL(value):
			return value
		case let .eft(value):
			return value
		case let .esi(value):
			return value
		case let .inGame(value):
			return value
		}
	}
	
	private func dnaRepresentation(_ loadout: (typeID: Int, data: NCFittingLoadout, name: String)) -> String {
		let slots: [NCFittingModuleSlot] = [.subsystem, .hi, .med, .low, .rig, .service]
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
			xml += "<fitting name=\"\(loadout.name.isEmpty ? type : loadout.name)\">\n<description value=\"\(NSLocalizedString("Created with Neocom on iOS", comment: ""))\"/>\n<shipType value=\"\(type)\"/>\n"
			
			let slots: [NCFittingModuleSlot] = [.hi, .med, .low, .rig, .subsystem, .service]
			for slot in slots {
				for (i, module) in (loadout.data.modules?[slot] ?? []).enumerated() {
					guard let type = invTypes[module.typeID]?.typeName else {continue}
					guard let slot = slot.name?.lowercased() else {continue}
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
			eft += "[\(type), \(loadout.name.isEmpty ? type : loadout.name)]\n"
			
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
	
	private func inGameRepresentation(_ loadout: (typeID: Int, data: NCFittingLoadout, name: String)) -> ESI.Fittings.MutableFitting {
		let fitting = ESI.Fittings.MutableFitting()
		fitting.shipTypeID = loadout.typeID
		
		let shipName: String = NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext -> String? in
			let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
			
			let modules = loadout.data.modules?.map { i -> FlattenBidirectionalCollection<[[ESI.Fittings.Item]]> in
				let flags: [ESI.Assets.Asset.Flag]
				switch i.key {
				case .hi:
					flags = [.hiSlot0, .hiSlot1, .hiSlot2, .hiSlot3, .hiSlot4, .hiSlot5, .hiSlot6, .hiSlot7]
				case .med:
					flags = [.medSlot0, .medSlot1, .medSlot2, .medSlot3, .medSlot4, .medSlot5, .medSlot6, .medSlot7]
				case .low:
					flags = [.loSlot0, .loSlot1, .loSlot2, .loSlot3, .loSlot4, .loSlot5, .loSlot6, .loSlot7]
				case .rig:
					flags = [.rigSlot0, .rigSlot1, .rigSlot2, .rigSlot3, .rigSlot4, .rigSlot5, .rigSlot6, .rigSlot7]
				case .subsystem:
					flags = [.subSystemSlot0, .subSystemSlot1, .subSystemSlot2, .subSystemSlot3, .subSystemSlot4, .subSystemSlot5, .subSystemSlot6, .subSystemSlot7]
				case .service:
					flags = [.structureServiceSlot0, .structureServiceSlot1, .structureServiceSlot2, .structureServiceSlot3, .structureServiceSlot4, .structureServiceSlot5, .structureServiceSlot6, .structureServiceSlot7]
				default:
					flags = [.cargo]
				}
				var slot = 0
				let items = i.value.map { j -> [ESI.Fittings.Item] in
					var items: [ESI.Fittings.Item] = []
					for _ in 0..<j.count {
						let item = ESI.Fittings.Item()
						item.quantity = 1
						item.typeID = j.typeID
						item.flag = flags[min(slot, flags.count - 1)].intValue
						slot += 1
						items.append(item)
					}
					return items
					}.joined()
				return items
				}.joined()
			
			let drones = loadout.data.drones?.flatMap { i -> ESI.Fittings.Item? in
				guard let type = invTypes[i.typeID] else {return nil}
				guard let categoryID = type.group?.category?.categoryID, let category = NCDBCategoryID(rawValue: Int(categoryID)) else {return nil}
				
				let item = ESI.Fittings.Item()
				item.quantity = i.count
				item.typeID = i.typeID
				
				item.flag = category == .fighter ? ESI.Assets.Asset.Flag.fighterBay.intValue : ESI.Assets.Asset.Flag.droneBay.intValue
				return item
				}
			
			var items: [ESI.Fittings.Item] = []
			if let modules = modules {
				items.append(contentsOf: modules)
			}
			if let drones = drones {
				items.append(contentsOf: drones)
			}
			
			fitting.items = items
			return invTypes[fitting.shipTypeID]?.typeName
		} ?? ""
		
		fitting.name = loadout.name.isEmpty ? shipName.isEmpty ? NSLocalizedString("Unnamed", comment: "") : shipName : loadout.name
		fitting.localizedDescription = NSLocalizedString("Created with Neocom on iOS", comment: "")

		return fitting
	}

	init?(value: Any) {
		if let data = value as? Data ?? (value as? String)?.data(using: .utf8) {
			if let loadouts = NCLoadoutRepresentation.loadoutsFrom(xml: data), !loadouts.isEmpty {
				self = .xml(loadouts)
				return
			}
			if let s = String(data: data, encoding: .utf8),
				let loadout = NCLoadoutRepresentation.loadoutFrom(eft: s) {
				self = .eft([loadout])
				return
			}
		}
		return nil
	}
	
	private static func loadoutsFrom(xml: Data) -> [(typeID: Int, data: NCFittingLoadout, name: String)]? {
		guard let object = (try? XMLParser.xmlObject(data: xml)) as? [String: Any] else {return nil}
		guard let root = object["fittings"] as? [String: Any] else {return nil}
		let fittings = root["fitting"] as? [[String: Any]] ?? [root["fitting"] as? [String: Any] ?? [:]]
		guard !fittings.isEmpty else {return nil}
		
		return NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext -> [(typeID: Int, data: NCFittingLoadout, name: String)] in
			return fittings.flatMap { fitting -> (typeID: Int, data: NCFittingLoadout, name: String)? in
				let name = fitting["name"] as? String ?? ""
				guard let typeName = (fitting["shipType"] as? [String: Any])?["value"] as? String else {return nil}
				guard let shipType: NCDBInvType = managedObjectContext.fetch("InvType", where: "typeName == %@", typeName) else {return nil}
				
				let hardware = fitting["hardware"] as? [[String: Any]] ?? [fitting["hardware"] as? [String: Any] ?? [:]]
			
				var invTypes = [String: NCDBInvType]()
				var modules = [NCFittingModuleSlot: [NCFittingLoadoutModule]]()
				var drones = [NCFittingLoadoutDrone]()
				
				for item in hardware {
					guard let typeName = item["type"] as? String else {continue}
					guard let slotName = (item["slot"] as? String)?.lowercased() else {continue}
					guard let type: NCDBInvType = invTypes[typeName] ?? managedObjectContext.fetch("InvType", where: "typeName == %@", typeName) else {continue}
					invTypes[typeName] = type

					let qty = item["qty"] as? Int ?? 1
					
					
					if slotName == "drone bay" || slotName == "fighter bay" {
						drones.append(NCFittingLoadoutDrone(typeID: Int(type.typeID), count: qty, identifier: nil))
					}
					else if let slot = NCFittingModuleSlot(name: slotName) {
						var array = modules[slot] ?? []
						array.append(NCFittingLoadoutModule(typeID: Int(type.typeID), count: qty, identifier: nil))
						modules[slot] = array
					}
					else {
						continue
					}
				}
				
				let loadout = NCFittingLoadout()
				loadout.modules = modules
				loadout.drones = drones
				
				return (typeID: Int(shipType.typeID), data: loadout, name: name)
			}
		}
	}
	
	private static func loadoutFrom(eft: String) -> (typeID: Int, data: NCFittingLoadout, name: String)? {
		var lines = eft.components(separatedBy: CharacterSet.newlines).filter{!$0.isEmpty}
		
		guard let ship: (String, String?) = {
			let s = lines.removeFirst().trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
			if let r = s.range(of: ",") {
				return (s.substring(to: r.lowerBound).trimmingCharacters(in: CharacterSet.whitespaces), s.substring(from: r.upperBound).trimmingCharacters(in: CharacterSet.whitespaces))
			}
			else {
				return (s.trimmingCharacters(in: CharacterSet.whitespaces), nil)
			}
		}()
			else {return nil}

		return NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext -> (typeID: Int, data: NCFittingLoadout, name: String)? in
			guard let shipType: NCDBInvType = managedObjectContext.fetch("InvType", where: "typeName == %@", ship.0) else {return nil}

			let regEx = try! NSRegularExpression(pattern: "(.*?)x(\\d+)$", options: [])

			var invTypes = [String: NCDBInvType]()
			var modules = [NCFittingModuleSlot: [NCFittingLoadoutModule]]()
			var drones = [NCFittingLoadoutDrone]()

			lines.forEach { line in
				let ns = line as NSString
				
				let qty: Int
				let s: String
				if let result = regEx.firstMatch(in: line, options: [], range: NSMakeRange(0, ns.length)) {
					s = ns.substring(with: result.range(at: 1))
					qty = Int(ns.substring(with: result.range(at: 2))) ?? 1
				}
				else {
					s = line
					qty = 1
				}
				
				let module: (String, String?) = {
					if let r = s.range(of: ",") {
						return (s.substring(to: r.lowerBound).trimmingCharacters(in: CharacterSet.whitespaces), s.substring(from: r.upperBound).trimmingCharacters(in: CharacterSet.whitespaces))
					}
					else {
						return (s.trimmingCharacters(in: CharacterSet.whitespaces), nil)
					}
				}()
				
				guard let type: NCDBInvType = invTypes[module.0] ?? managedObjectContext.fetch("InvType", where: "typeName == %@", module.0) else {return}
				guard let categoryID = (type.dgmppItem?.groups?.anyObject() as? NCDBDgmppItemGroup)?.category?.category else {return}
				guard let category = NCDBDgmppItemCategoryID(rawValue: Int(categoryID)) else {return}
				invTypes[module.0] = type

				switch category {
				case .hi, .med, .low, .rig, .subsystem, .service, .structureRig:
					let slot: NCFittingModuleSlot
					switch category {
					case .hi:
						slot = .hi
					case .med:
						slot = .med
					case .low:
						slot = .low
					case .rig:
						slot = .rig
					case .subsystem:
						slot = .subsystem
					case .service:
						slot = .service
					default:
						slot = .rig
					}
					
					let charge: NCFittingLoadoutItem? = {
						guard let typeName = module.1 else {return nil}
						guard let type: NCDBInvType = invTypes[typeName] ?? managedObjectContext.fetch("InvType", where: "typeName == %@", typeName) else {return nil}
						invTypes[typeName] = type
						return NCFittingLoadoutItem(typeID: Int(type.typeID), count: 1, identifier: nil)
					}()
					
					var array = modules[slot] ?? []
					array.append(NCFittingLoadoutModule(typeID: Int(type.typeID), count: qty, identifier: nil, charge: charge))
					modules[slot] = array
				case .drone, .structureDrone:
					drones.append(NCFittingLoadoutDrone(typeID: Int(type.typeID), count: qty, identifier: nil))
				default:
					return
				}
			}

			let loadout = NCFittingLoadout()
			loadout.modules = modules
			loadout.drones = drones
			
			return (typeID: Int(shipType.typeID), data: loadout, name: ship.1 ?? "")
		}

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
				let name = loadout.name.isEmpty ? typeName : loadout.name
				
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
