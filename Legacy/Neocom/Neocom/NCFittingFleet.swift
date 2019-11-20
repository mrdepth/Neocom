//
//  NCFittingFleet.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import EVEAPI
import Dgmpp

public extension Notification.Name {
	public static let NCFittingFleetDidUpdate = Notification.Name(rawValue: "NCFittingFleetDidUpdate")
}

class NCFittingFleet {
	
	var pilots = [(DGMCharacter, NSManagedObjectID?)]()
	var structure: (DGMStructure, NSManagedObjectID?)?
	var active: DGMCharacter? {
		didSet {
			NotificationCenter.default.post(name: .NCFittingFleetDidUpdate, object: self)
		}
	}
	var fleetID: NSManagedObjectID?
	let gang: DGMGang = try! DGMGang()
	
	init(loadouts: [NCLoadout]) {
		for loadout in loadouts {
			_ = try? append(loadout: loadout)
		}
	}
	
	init(typeID: Int) throws {
		let isStructure = NCDatabase.sharedDatabase?.performTaskAndWait { (context) -> Bool in
			return (NCDBInvType.invTypes(managedObjectContext: context)[typeID]?.dgmppItem?.groups?.anyObject() as? NCDBDgmppItemGroup)?.category?.category == Int32(NCDBDgmppItemCategoryID.structure.rawValue)
		} ?? false
		if isStructure {
			structure = (try DGMStructure(typeID: typeID), nil)
		}
		else {
			let pilot = try DGMCharacter()
			pilot.ship = try DGMShip(typeID: typeID)
			gang.add(pilot)
			pilots.append((pilot, nil))
			active = pilot
		}
	}

	convenience init(fleet: NCFleet) {
		self.init(loadouts: fleet.loadouts?.array as? [NCLoadout] ?? [])
		self.fleetID = fleet.objectID
		if let configuration = fleet.configuration {
			self.configuration = configuration
		}
	}

    convenience init(asset: NCAsset, contents: [Int64: [NCAsset]]) throws {
		try self.init(typeID: asset.typeID)
		let pilot = active!
		let ship = pilot.ship!
		
		var cargo = Set<Int>()
		var requiresAmmo = [DGMModule]()
		
		contents[asset.itemID]?.forEach {
			do {
				
				switch $0.flag {
				case .drone?:
					for _ in 0..<$0.quantity {
						try ship.add(DGMDrone(typeID: $0.typeID))
					}
				case .cargo?:
					cargo.insert($0.typeID)
				default:
					for _ in 0..<$0.quantity {
						let module = try DGMModule(typeID: $0.typeID)
						try ship.add(module, ignoringRequirements: true)
						if (!module.chargeGroups.isEmpty) {
							requiresAmmo.append(module)
						}
					}
				}
			}
			catch {
			}
		}
		
		for module in requiresAmmo {
			for typeID in cargo {
				do {
					try module.setCharge(DGMCharge(typeID: typeID))
					break
				}
				catch {
				}
			}
		}
	}
	
	convenience init(killmail: NCKillmail) throws {
		try self.init(typeID: killmail.getVictim().shipTypeID)
		let pilot = active!
		let ship = pilot.ship!

		var cargo = Set<Int>()
		var requiresAmmo = [DGMModule]()
		
		killmail.getItems()?.forEach {
			do {
				let qty = Int(($0.quantityDropped ?? 0) + ($0.quantityDestroyed ?? 0))
				switch ESI.Assets.Asset.Flag($0.flag) {
				case .droneBay?, .fighterBay?, .fighterTube0?, .fighterTube1?, .fighterTube2?, .fighterTube3?, .fighterTube4?:
					for _ in 0..<max(qty, 1) {
						try ship.add(DGMDrone(typeID: $0.itemTypeID))
					}
				case .cargo?:
					cargo.insert($0.itemTypeID)
				default:
					for _ in 0..<max(qty, 1) {
						let module = try DGMModule(typeID: $0.itemTypeID)
						try ship.add(module, ignoringRequirements: true)
						if (!module.chargeGroups.isEmpty) {
							requiresAmmo.append(module)
						}
					}
				}
			}
			catch {
			}
		}
		
		for module in requiresAmmo {
			for typeID in cargo {
				do {
					try module.setCharge(DGMCharge(typeID: typeID))
					break
				}
				catch {
				}
			}
		}
	}

	convenience init(fitting: ESI.Fittings.Fitting) throws {
		try self.init(typeID: fitting.shipTypeID)
		let pilot = active!
		let ship = pilot.ship!

		var cargo = Set<Int>()
		var requiresAmmo = [DGMModule]()
		
		fitting.items.forEach {
			do {
				switch ESI.Assets.Asset.Flag($0.flag) {
				case .droneBay?, .fighterBay?, .fighterTube0?, .fighterTube1?, .fighterTube2?, .fighterTube3?, .fighterTube4?:
					for _ in 0..<max($0.quantity, 1) {
						try ship.add(DGMDrone(typeID: $0.typeID))
					}
				case .cargo?:
					cargo.insert($0.typeID)
				default:
					for _ in 0..<max($0.quantity, 1) {
						let module = try DGMModule(typeID: $0.typeID)
						try ship.add(module, ignoringRequirements: true)
						if (!module.chargeGroups.isEmpty) {
							requiresAmmo.append(module)
						}
					}
				}
			}
			catch {
				
			}
		}
		
		for module in requiresAmmo {
			for typeID in cargo {
				do {
					try module.setCharge(DGMCharge(typeID: typeID))
					break
				}
				catch {
				}
			}
		}

	}
	
	func append(loadout: NCLoadout) throws {
		
		let typeID = Int(loadout.typeID)
		let isStructure = NCDatabase.sharedDatabase?.performTaskAndWait { (context) -> Bool in
			return (NCDBInvType.invTypes(managedObjectContext: context)[typeID]?.dgmppItem?.groups?.anyObject() as? NCDBDgmppItemGroup)?.category?.category == Int32(NCDBDgmppItemCategoryID.structure.rawValue)
			} ?? false
		
		if isStructure {
			structure = (try DGMStructure(typeID: typeID), loadout.objectID)
			structure?.0.name = loadout.name ?? ""
			if let data = loadout.data?.data {
				structure?.0.loadout = data
			}
		}
		else {
			let pilot = try DGMCharacter()
			pilot.ship = try DGMShip(typeID: typeID)
			pilot.ship?.name = loadout.name ?? ""
			if let data = loadout.data?.data {
				pilot.loadout = data
			}
			
			gang.add(pilot)
			pilots.append((pilot, loadout.objectID))
			
			if active == nil {
				active = pilot
			}
		}
	}
	
	func append(typeID: Int) throws {
		let isStructure = NCDatabase.sharedDatabase?.performTaskAndWait { (context) -> Bool in
			return (NCDBInvType.invTypes(managedObjectContext: context)[typeID]?.dgmppItem?.groups?.anyObject() as? NCDBDgmppItemGroup)?.category?.category == Int32(NCDBDgmppItemCategoryID.structure.rawValue)
			} ?? false
		
		if isStructure {
			structure = (try DGMStructure(typeID: typeID), nil)
		}
		else {
			let pilot = try DGMCharacter()
			pilot.ship = try DGMShip(typeID: typeID)
			gang.add(pilot)
			pilots.append((pilot, nil))
			if active == nil {
				active = pilot
			}
		}
	}
	
	func add(pilot: DGMCharacter) {
		gang.add(pilot)
		pilots.append((pilot, nil))
		if active == nil {
			active = pilot
		}
	}
	
	func remove(pilot: DGMCharacter) {
		if active == pilot {
			active = pilots.first(where: { $0.0 != pilot })?.0
		}
		if let i = pilots.index(where: { $0.0 == pilot }) {
			pilots.remove(at: i)
		}
		gang.remove(pilot)
		
	}
	
	var configuration: NCFleetConfiguration {
		get {
			let configuration = NCFleetConfiguration()
			var pilots = [Int: String]()
			for (pilot, _) in self.pilots {
				pilots[pilot.identifier] = pilot.url?.absoluteString ?? DGMCharacter.url(level: 5).absoluteString
			}
			var links = [Int: Int]()
			for (pilot, _) in self.pilots {
				for module in pilot.ship?.modules ?? [] {
					if let target = module.target?.parent {
						links[module.identifier] = target.identifier
					}
				}
				for drone in pilot.ship?.drones ?? [] {
					if let target = drone.target?.parent {
						links[drone.identifier] = target.identifier
					}
				}
			}
			configuration.pilots = pilots
			configuration.links = links
			return configuration
		}
		set {
			let configuration = newValue
			var pilotsMap = [Int: DGMCharacter]()
			
			for (pilot, _) in self.pilots {
				pilotsMap[pilot.identifier] = pilot
			}
			for (identifier, character) in configuration.pilots ?? [:]{
				guard let pilot = pilotsMap[identifier], let url = URL(string:character) else {continue}
				pilot.setSkills(from: url)
			}
			for (pilot, _) in self.pilots {
				for module in pilot.ship?.modules ?? [] {
					guard let link = configuration.links?[module.identifier] else {continue}
					module.target = pilotsMap[link]?.ship
				}
				for drone in pilot.ship?.drones ?? [] {
					guard let link = configuration.links?[drone.identifier] else {continue}
					drone.target = pilotsMap[link]?.ship
				}
			}
		}
	}

}

//fileprivate extension NCFittingGang {
//	func addPilot(typeID: Int) -> NCFittingCharacter?  {
//		guard let pilot = addPilot() else {return nil}
//		let categoryID = NCDatabase.sharedDatabase?.performTaskAndWait { managedObjectContext -> NCDBDgmppItemCategoryID? in
//			let invTypes = NCDBInvType.invTypes(managedObjectContext: managedObjectContext)
//			guard let categoryID = (invTypes[typeID]?.dgmppItem?.groups?.anyObject() as? NCDBDgmppItemGroup)?.category?.category else {return nil}
//			return NCDBDgmppItemCategoryID(rawValue: Int(categoryID))
//		}
//		if categoryID == .structure {
//			pilot.structure = NCFittingStructure(typeID: typeID)
//		}
//		else {
//			pilot.ship = NCFittingShip(typeID: typeID)
//		}
//		return pilot
//	}
//}

