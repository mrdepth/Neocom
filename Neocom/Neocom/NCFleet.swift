//
//  NCFleet.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

class NCFleet {
	var pilots = [NCFittingCharacter: NCLoadout?]()
	var active: NCFittingCharacter?
	
	init(loadouts:[NCLoadout], engine: NCFittingEngine) {
		let gang = engine.gang
		for loadout in loadouts {
			guard let data = loadout.data?.data else {continue}
			let pilot = gang.addPilot()
			pilot.ship = NCFittingShip(typeID: Int(loadout.typeID))
			pilot.loadout = data
			pilots[pilot] = loadout
		}
		active = pilots.first?.key
	}
	
	init(typeID: Int, engine: NCFittingEngine) {
		let gang = engine.gang
		let pilot = gang.addPilot()
		pilot.ship = NCFittingShip(typeID: typeID)
		pilots[pilot] = nil as NCLoadout?
		active = pilots.first?.key
	}
}
