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
	
	init(fleet: NCFleet, engine: NCFittingEngine) {
	}
	
	init(loadouts:[NCLoadout], engine: NCFittingEngine) {
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
	}
	
	func append(loadout: NCLoadout, engine: NCFittingEngine) {
		guard let data = loadout.data?.data else {return}
		let gang = engine.gang
		let pilot = gang.addPilot()
		
		pilot.ship = NCFittingShip(typeID: Int(loadout.typeID))
		pilot.ship?.name = loadout.name ?? ""
		pilot.loadout = data
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
}
