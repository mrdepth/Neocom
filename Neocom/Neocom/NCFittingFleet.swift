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
	var pilots = [NCFittingCharacter: NSManagedObjectID?]()
	var active: NCFittingCharacter?
	var fleet: NCFleet?
	let engine: NCFittingEngine
	
	init(fleet: NCFleet, engine: NCFittingEngine) {
		self.fleet = fleet
		self.engine = engine
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
		pilots[pilot] = nil as NSManagedObjectID?
		active = pilots.first?.key
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
		pilots[pilot] = loadout.objectID
		
		if active == nil {
			active = pilot
		}
	}
	
	func append(typeID: Int, engine: NCFittingEngine) {
		let gang = engine.gang
		let pilot = gang.addPilot()
		pilot.ship = NCFittingShip(typeID: typeID)
		pilots[pilot] = nil as NSManagedObjectID?
		active = pilots.first?.key
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
						links[module.identifier!] = target.identifier!
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
	}

}
