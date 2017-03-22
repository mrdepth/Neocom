//
//  NCFittingFleet.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

class NCFittingFleet {
	var pilots = [(NCFittingCharacter, NSManagedObjectID?)]()
	var active: NCFittingCharacter? {
		didSet {
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: .NCFittingEngineDidUpdate, object: self.engine)
			}
		}
	}
	var fleetID: NSManagedObjectID?
	let engine: NCFittingEngine
	
	init(fleet: NCFleet, engine: NCFittingEngine) {
		self.fleetID = fleet.objectID
		self.engine = engine
		for loadout in fleet.loadouts?.array as? [NCLoadout] ?? [] {
			append(loadout: loadout, engine: engine)
		}
		if let configuration = fleet.configuration {
			self.configuration = configuration
		}
	}
	
	init(loadouts:[NCLoadout], engine: NCFittingEngine) {
		self.engine = engine
		for loadout in loadouts {
			append(loadout: loadout, engine: engine)
		}
	}
	
	init(typeID: Int, engine: NCFittingEngine) {
		let gang = engine.gang
		let pilot = gang.addPilot()
		pilot.ship = NCFittingShip(typeID: typeID)
		pilots.append((pilot, nil))
		active = pilots.first?.0
		self.engine = engine
	}
	
	func append(loadout: NCLoadout, engine: NCFittingEngine) {
		guard let data = loadout.data?.data else {return}
		let gang = engine.gang
		let pilot = gang.addPilot()
		
		pilot.ship = NCFittingShip(typeID: Int(loadout.typeID))
		pilot.ship?.name = loadout.name ?? ""
		pilot.loadout = data
		pilot.identifier = loadout.uuid
		pilots.append((pilot, loadout.objectID))
		
		if active == nil {
			active = pilot
		}
	}
	
	func append(typeID: Int, engine: NCFittingEngine) {
		let gang = engine.gang
		let pilot = gang.addPilot()
		pilot.ship = NCFittingShip(typeID: typeID)
		pilots.append((pilot, nil))
		active = pilots.first?.0
	}
	
	func remove(pilot: NCFittingCharacter) {
		if active == pilot {
			active = pilots.first(where: { $0.0 != pilot })?.0
		}
		if let i = pilots.index(where: { $0.0 == pilot }) {
			pilots.remove(at: i)
		}
		engine.gang.removePilot(pilot)
		
	}
	
	var configuration: NCFleetConfiguration {
		get {
			let configuration = NCFleetConfiguration()
			var pilots = [String: String]()
			for (pilot, _) in self.pilots {
				if pilot.identifier == nil {
					pilot.identifier = UUID().uuidString
				}
				pilots[pilot.identifier!] = pilot.url?.absoluteString ?? NCFittingCharacter.url(level: 5).absoluteString
			}
			var links = [String: String]()
			for (pilot, _) in self.pilots {
				for module in pilot.ship?.modules ?? [] {
					if let target = module.target {
						if module.identifier == nil {
							module.identifier = UUID().uuidString
						}
						links[module.identifier!] = target.owner!.identifier!
					}
				}
				for drone in pilot.ship?.drones ?? [] {
					if let target = drone.target {
						if drone.identifier == nil {
							drone.identifier = UUID().uuidString
						}
						links[drone.identifier!] = target.identifier!
					}
				}
			}
			configuration.pilots = pilots
			configuration.links = links
			configuration.squadBooster = engine.gang.squadBooster?.identifier
			configuration.fleetBooster = engine.gang.fleetBooster?.identifier
			configuration.wingBooster = engine.gang.wingBooster?.identifier
			return configuration
		}
		set {
			let configuration = newValue
			var pilotsMap = [String: NCFittingCharacter]()
			
			for (pilot, _) in self.pilots {
				guard let identifier = pilot.identifier else {continue}
				pilotsMap[identifier] = pilot
			}
			for (identifier, character) in configuration.pilots ?? [:]{
				guard let pilot = pilotsMap[identifier], let url = URL(string:character) else {continue}
				pilot.setSkills(from: url)
			}
			for (pilot, _) in self.pilots {
				for module in pilot.ship?.modules ?? [] {
					guard let identifier = module.identifier, let link = configuration.links?[identifier] else {continue}
					module.target = pilotsMap[link]?.ship
				}
				for drone in pilot.ship?.drones ?? [] {
					guard let identifier = drone.identifier, let link = configuration.links?[identifier] else {continue}
					drone.target = pilotsMap[link]?.ship
				}
			}
			let gang = self.engine.gang
			if let fleetBooster = configuration.fleetBooster {
				gang.fleetBooster = pilotsMap[fleetBooster]
			}
			if let squadBooster = configuration.squadBooster {
				gang.squadBooster = pilotsMap[squadBooster]
			}
			if let wingBooster = configuration.wingBooster {
				gang.wingBooster = pilotsMap[wingBooster]
			}
		}
	}

}
