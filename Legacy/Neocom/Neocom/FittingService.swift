//
//  FittingService.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/02/2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp

class FittingService {
	
}


extension DGMShip {
	var loadout: LoadoutDescription {
		get {
			let loadout = LoadoutDescription()
			
			var drones = [Int: LoadoutDescription.Item.Drone]()
			for drone in self.drones {
				let identifier = drone.identifier
				if let drone = drones[identifier] {
					drone.count += 1
				}
				else {
					drones[identifier] = LoadoutDescription.Item.Drone(drone: drone)
				}
			}
			
			loadout.drones = Array(drones.values)
			
			var modules = [DGMModule.Slot: [LoadoutDescription.Item.Module]]()
			
			for module in self.modules {
				modules[module.slot, default: []].append(LoadoutDescription.Item.Module(module: module))
			}
			
			loadout.modules = modules
			
			return loadout
		}
		set {
			for drone in newValue.drones ?? [] {
				do {
					let identifier = drone.identifier ?? UUID().hashValue
					for _ in 0..<drone.count {
						let item = try DGMDrone(typeID: drone.typeID)
						try add(item, squadronTag: drone.squadronTag)
						item.isActive = drone.isActive
						item.isKamikaze = drone.isKamikaze
						item.identifier = identifier
					}
				}
				catch {
				}
			}
			for (_, modules) in newValue.modules?.sorted(by: { $0.key.rawValue > $1.key.rawValue }) ?? [] {
				for module in modules {
					do {
						let identifier = module.identifier ?? UUID().hashValue
						for _ in 0..<module.count {
							let item = try DGMModule(typeID: module.typeID)
							try add(item, socket: module.socket, ignoringRequirements: true)
							item.identifier = identifier
							item.state = module.state
							if let charge = module.charge {
								try item.setCharge(DGMCharge(typeID: charge.typeID))
							}
						}
					}
					catch {
					}
				}
			}
		}
	}
}

extension DGMCharacter {
	var loadout: LoadoutDescription {
		get {
			let loadout = self.ship?.loadout ?? LoadoutDescription()
			loadout.implants = implants.map{ LoadoutDescription.Item(type: $0) }
			loadout.boosters = boosters.map{ LoadoutDescription.Item(type: $0) }
			return loadout
		}
		set {
			for implant in newValue.implants ?? [] {
				try? add(DGMImplant(typeID: implant.typeID))
			}
			for booster in newValue.boosters ?? [] {
				try? add(DGMBooster(typeID: booster.typeID))
			}
			ship?.loadout = newValue
		}
	}
	
	class func url(account: Account) -> URL? {
		guard let uuid = account.uuid else {return nil}
		var components = URLComponents()
		components.scheme = URLScheme.nc.rawValue
		components.host = "character"
		
		var queryItems = [URLQueryItem(name: "accountUUID", value: uuid)]
		
		if let name = account.characterName {
			queryItems.append(URLQueryItem(name: "name", value: name))
		}
		queryItems.append(URLQueryItem(name: "characterID", value: "\(account.characterID)"))
		
		components.queryItems = queryItems
		return components.url!
	}
	
	class func url(level: Int) -> URL {
		var components = URLComponents()
		components.scheme = URLScheme.nc.rawValue
		components.host = "character"
		components.queryItems = [
			URLQueryItem(name: "level", value: String(level)),
			URLQueryItem(name: "name", value: NSLocalizedString("All Skills", comment: "") + " " + String(romanNumber: level))
		]
		return components.url!
	}
	
	class func url(character: FitCharacter) -> URL? {
		guard let uuid = character.uuid else {return nil}
		var components = URLComponents()
		components.scheme = URLScheme.nc.rawValue
		components.host = "character"
		components.queryItems = [
			URLQueryItem(name: "characterUUID", value: uuid),
			URLQueryItem(name: "name", value: character.name ?? "")
		]
		return components.url!
	}
	
	var url: URL? {
		return URL(string: name)
	}

	/*var account: Account? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let accountUUID = components.queryItems?.first(where: {$0.name == "accountUUID"})?.value else {return nil}
		return Services.storage.viewContext.accounts.first{$0.uuid == accountUUID}
	}
	
	var fitCharacter: FitCharacter? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let characterUUID = components.queryItems?.first(where: {$0.name == "characterUUID"})?.value else {return nil}
		let character: FitCharacter? = NCStorage.sharedStorage?.viewContext.fetch("FitCharacter", where: "uuid == %@", characterUUID)
		return character
	}
	
	var level: Int? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let level = components.queryItems?.first(where: {$0.name == "level"})?.value else {return nil}
		return Int(level)
	}*/
}
