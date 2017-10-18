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
	private(set) var itemName: String?
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
		itemName = station.stationName
		if let solarSystem = station.solarSystem {
			solarSystemName = solarSystem.solarSystemName
			solarSystemID = Int(solarSystem.solarSystemID)
			security = solarSystem.security
		}
	}
	
	convenience init(_ solarSystem: NCDBMapSolarSystem) {
		self.init()
		solarSystemID = Int(solarSystem.solarSystemID)
		solarSystemName = solarSystem.solarSystemName
		security = solarSystem.security
	}
	
	convenience init(_ mapDenormalize: NCDBMapDenormalize) {
		self.init(mapDenormalize.solarSystem!)
		if mapDenormalize.itemID != mapDenormalize.solarSystem?.solarSystemID {
			itemName = mapDenormalize.itemName
		}
	}

	convenience init(_ structure: ESI.Universe.StructureInformation) {
		if let solarSystem = NCDatabase.sharedDatabase?.mapSolarSystems[structure.solarSystemID] {
			self.init(solarSystem)
		}
		else {
			self.init()
		}
		self.itemName = structure.name
	}

	init?(_ name: ESI.Universe.Name) {
		switch name.category {
		case .station:
			self.stationID = name.id
			self.itemName = name.name
		case .solarSystem:
			self.solarSystemID = name.id
			self.solarSystemName = name.name
		default:
			return nil
		}
	}

	lazy var displayName: NSAttributedString = {
		let s = NSMutableAttributedString()
		if let security = self.security {
			s.append(NSAttributedString(string: String(format: "%.1f ", security) , attributes: [NSAttributedStringKey.foregroundColor: UIColor(security: security)]))
		}
		if let itemName = self.itemName {
			if let solarSystemName = self.solarSystemName {
				let r = (itemName as NSString).range(of: solarSystemName)
				if r.length > 0  {
					let title = NSMutableAttributedString(string: itemName)
					title.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], range: r)
					s.append(title)
				}
				else {
					s.append(NSAttributedString(string: itemName))
				}
			}
			else {
				s.append(NSAttributedString(string: itemName))
			}
		}
		else if let solarSystemName = self.solarSystemName {
			s.append(NSAttributedString(string: solarSystemName))
		}
		return s
	}()
}
