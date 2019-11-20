//
//  FittingContext.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/02/2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp
import CoreData

class FittingContext {
	let gang: DGMGang
	var structure: DGMStructure?
	var persistentObjects: [DGMObject: NSManagedObject] = [:]
	
	init() throws {
		gang = try DGMGang()
	}
	
	func add(typeID: Int, context: SDEContext) throws -> DGMShip {
		guard let invType = context.invType(typeID) else {throw NCError.invalidArgument(type: type(of: self), function: #function, argument: "typeID", value: typeID)}
		return try add(type: invType)
	}
	
	func add(type: SDEInvType) throws -> DGMShip {
		switch type.dgmppItemCategoryID {
		case .ship?:
			let pilot = try DGMCharacter()
			pilot.ship = try DGMShip(typeID: DGMTypeID(type.typeID))
			gang.add(pilot)
			return pilot.ship!
		case .structure?:
			let structure = try DGMStructure(typeID: DGMTypeID(type.typeID))
			return structure
		default:
			throw NCError.invalidArgument(type: Swift.type(of: self), function: #function, argument: "type", value: type)
		}
	}
	
	@discardableResult
	func add(loadout: Loadout, context: SDEContext) throws -> DGMShip {
		guard let invType = context.invType(DGMTypeID(loadout.typeID)) else {throw NCError.invalidArgument(type: type(of: self), function: #function, argument: "typeID", value: loadout.typeID)}
		
		switch invType.dgmppItemCategoryID {
		case .ship?:
			let pilot = try DGMCharacter()
			pilot.ship = try DGMShip(typeID: DGMTypeID(invType.typeID))
			gang.add(pilot)
			return pilot.ship!
		case .structure?:
			let structure = try DGMStructure(typeID: DGMTypeID(invType.typeID))
			structure.name = loadout.name ?? ""
			return structure
		default:
			throw NCError.invalidArgument(type: Swift.type(of: self), function: #function, argument: "type", value: invType)
		}
	}
	
}
