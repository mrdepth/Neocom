//
//  NCLocation.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class NCLocation {
	private(set) var stationID: Int?
	private(set) var stationName: String?
	private(set) var stationTypeID: Int?
	private(set) var solarSystemID: Int?
	private(set) var solarSystemName: String?
	private(set) var corporationID: Int?
	private(set) var corporationName: String?
	private(set) var security: Float?
	
	init() {
		
	}
	
	convenience init(_ station: NCDBStaStation) {
		self.init(station.solarSystem!)
		stationID = Int(station.stationID)
		stationName = station.stationName
	}
	
	convenience init(_ solarSystem: NCDBMapSolarSystem) {
		self.init()
		solarSystemID = Int(solarSystem.solarSystemID)
		solarSystemName = solarSystem.solarSystemName
		security = solarSystem.security
	}
	
	convenience init(_ mapDenormalize: NCDBMapDenormalize) {
		self.init(mapDenormalize.solarSystem!)
	}

	convenience init(_ structure: ESI.Universe.StructureInformation) {
		if let solarSystem = NCDatabase.sharedDatabase?.mapSolarSystems[structure.solarSystemID] {
			self.init(solarSystem)
		}
		else {
			self.init()
		}
		self.stationName = structure.name
	}

	init?(_ name: ESI.Universe.Name) {
		switch name.category {
		case .station:
			self.stationID = name.id
			self.stationName = name.name
		case .solarSystem:
			self.solarSystemID = name.id
			self.solarSystemName = name.name
		default:
			return nil
		}
	}

	var displayName: NSAttributedString {
		let s = NSMutableAttributedString()
		if let security = self.security {
			s.append(NSAttributedString(string: String(format: "%.1f ", security) , attributes: [NSForegroundColorAttributeName: UIColor(security: security)]))
		}
		if let stationName = stationName {
			s.append(NSAttributedString(string: stationName))
		}
		else if let solarSystemName = solarSystemName {
			s.append(NSAttributedString(string: solarSystemName))
		}
		return s
	}
}
