//
//  EVELocation.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/26/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

struct EVELocation: Hashable {
	let displayName: NSAttributedString
	
	init(_ station: SDEStaStation) {
		self.init(stationID: Int(station.stationID),
				  itemName: station.stationName,
				  stationTypeID: (station.stationType?.typeID).map{Int($0)},
				  solarSystemID: (station.solarSystem?.solarSystemID).map{Int($0)},
				  solarSystemName: station.solarSystem?.solarSystemName,
				  corporationID: nil,
				  corporationName: nil,
				  security: station.solarSystem?.security)
	}
	
	init(_ solarSystem: SDEMapSolarSystem) {
		self.init(stationID: nil,
				  itemName: nil,
				  stationTypeID: nil,
				  solarSystemID: Int(solarSystem.solarSystemID),
				  solarSystemName: solarSystem.solarSystemName,
				  corporationID: nil,
				  corporationName: nil,
				  security: solarSystem.security)
	}
	
	init(_ structure: ESI.Universe.StructureInformation) {

		let result = (try? Services.sde.performBackgroundTask { context -> (String?, Float)? in
			guard let solarSystem = context.mapSolarSystem(structure.solarSystemID) else {return nil}
			return (solarSystem.solarSystemName, solarSystem.security)
			}.get()) ?? nil
		
		self.init(stationID: nil,
				  itemName: structure.name,
				  stationTypeID: nil,
				  solarSystemID: structure.solarSystemID,
				  solarSystemName: result?.0,
				  corporationID: nil,
				  corporationName: nil,
				  security: result?.1)
	}
	
	init?(_ name: ESI.Universe.Name) {
		switch name.category {
		case .station:
			self.init(stationID: name.id,
					  itemName: name.name,
					  stationTypeID: nil,
					  solarSystemID: nil,
					  solarSystemName: nil,
					  corporationID: nil,
					  corporationName: nil,
					  security: nil)
		case .solarSystem:
			let result = (try? Services.sde.performBackgroundTask { context -> (String?, Float)? in
				guard let solarSystem = context.mapSolarSystem(name.id) else {return nil}
				return (solarSystem.solarSystemName, solarSystem.security)
				}.get()) ?? nil

			
			self.init(stationID: nil,
					  itemName: nil,
					  stationTypeID: nil,
					  solarSystemID: name.id,
					  solarSystemName: result?.0,
					  corporationID: nil,
					  corporationName: nil,
					  security: result?.1)
		default:
			self.init(stationID: nil,
					  itemName: name.name,
					  stationTypeID: nil,
					  solarSystemID: nil,
					  solarSystemName: nil,
					  corporationID: nil,
					  corporationName: nil,
					  security: nil)
		}
	}
	
	init(stationID: Int?,
		 itemName: String?,
		 stationTypeID: Int?,
		 solarSystemID: Int?,
		 solarSystemName: String?,
		 corporationID: Int?,
		 corporationName: String?,
		 security: Float?) {
		
		let s = NSMutableAttributedString()
		if let security = security {
			s.append(NSAttributedString(string: String(format: "%.1f ", security) , attributes: [NSAttributedString.Key.foregroundColor: UIColor(security: security)]))
		}
		if let itemName = itemName {
			if let solarSystemName = solarSystemName {
				let r = (itemName as NSString).range(of: solarSystemName)
				if r.length > 0  {
					let title = NSMutableAttributedString(string: itemName)
					title.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], range: r)
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
		else if let solarSystemName = solarSystemName {
			s.append(NSAttributedString(string: solarSystemName))
		}
		
		displayName = s
	}
	
}
