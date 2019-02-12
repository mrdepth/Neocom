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
	struct Pilot {
		var character: DGMCharacter
		var loadoutID: NSManagedObjectID?
	}
	
	struct Structure {
		var structure: DGMStructure
		var loadoutID: NSManagedObjectID?
	}

	let gang: DGMGang
	var fleet: Fleet?
	
	
	init() throws {
		gang = try DGMGang()
	}
	
}
