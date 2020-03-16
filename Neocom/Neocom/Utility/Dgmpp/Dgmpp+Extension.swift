//
//  Dgmpp+Extension.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/24/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import CoreData
import Expressible
import Combine
import EVEAPI
import Alamofire

extension DGMType {
    func type(from managedObjectContext: NSManagedObjectContext) -> SDEInvType? {
        try? managedObjectContext.from(SDEInvType.self)
            .filter(/\SDEInvType.typeID == Int32(self.typeID))
            .first()
    }
}


extension DGMModule.Slot {
    var image: Image? {
        switch self {
        case .hi:
            return Image("slotHigh")
        case .med:
            return Image("slotMed")
        case .low:
            return Image("slotLow")
        case .rig:
            return Image("slotRig")
        case .subsystem:
            return Image("slotSubsystem")
        case .service:
            return Image("slotService")
        case .mode:
            return Image("slotSubsystem")
        default:
            return nil
        }
    }
    
    var title: String? {
        switch self {
        case .hi:
            return NSLocalizedString("Hi Slot", comment: "")
        case .med:
            return NSLocalizedString("Med Slot", comment: "")
        case .low:
            return NSLocalizedString("Low Slot", comment: "")
        case .rig:
            return NSLocalizedString("Rig Slot", comment: "")
        case .subsystem:
            return NSLocalizedString("Subsystem Slot", comment: "")
        case .service:
            return NSLocalizedString("Service Slot", comment: "")
        case .mode:
            return NSLocalizedString("Tactical Mode", comment: "")
        default:
            return nil
        }
    }
    
    var name: String? {
        switch self {
        case .hi:
            return "Hi Slot"
        case .med:
            return "Med Slot"
        case .low:
            return "Low Slot"
        case .rig:
            return "Rig Slot"
        case .subsystem:
            return "Subsystem Slot"
        case .service:
            return "Service Slot"
        case .mode:
            return "Tactical Mode"
        default:
            return nil
        }
    }
    
    init?(name: String) {
        if name.range(of: "hi slot")?.lowerBound == name.startIndex {
            self = .hi
        }
        else if name.range(of: "med slot")?.lowerBound == name.startIndex {
            self = .med
        }
        else if name.range(of: "low slot")?.lowerBound == name.startIndex {
            self = .low
        }
        else if name.range(of: "rig slot")?.lowerBound == name.startIndex {
            self = .rig
        }
        else if name.range(of: "subsystem slot")?.lowerBound == name.startIndex {
            self = .subsystem
        }
        else if name.range(of: "service slot")?.lowerBound == name.startIndex {
            self = .service
        }
        else {
            return nil
        }
    }
}

extension DGMModule.State {
    var image: Image? {
        switch self {
        case .offline:
            return Image("offline")
        case .online:
            return Image("online")
        case .active:
            return Image("active")
        case .overloaded:
            return Image("overheated")
        default:
            return nil
        }
    }
    
    var title: String? {
        switch self {
        case .offline:
            return NSLocalizedString("Offline", comment: "")
        case .online:
            return NSLocalizedString("Online", comment: "")
        case .active:
            return NSLocalizedString("Active", comment: "")
        case .overloaded:
            return NSLocalizedString("Overheated", comment: "")
        default:
            return nil
        }
    }
}

enum DGMAccuracy {
    case none
    case low
    case average
    case good
}

extension DGMAccuracy {
    var color: Color? {
        switch self {
        case .none:
            return nil
        case .low:
            return Color(.systemRed)
        case .average:
            return Color(.systemYellow)
        case .good:
            return Color(.systemGreen)
        }
    }
}

extension DGMModule {
    func accuracy(targetSignature: DGMMeter, hitChance: DGMPercent = 0.75) -> DGMAccuracy{
        guard let ship = parent as? DGMShip else {return .none}
        
        let optimal = self.optimal
        let falloff = self.falloff
        let angularVelocity = self.angularVelocity(targetSignature: targetSignature, hitChance: hitChance) * DGMSeconds(1)
        guard angularVelocity > 0 else {return .none}
        
        let v0 = ship.maxVelocityInOrbit(optimal) * DGMSeconds(1)
        let v1 = ship.maxVelocityInOrbit(optimal + falloff) * DGMSeconds(1)
        if angularVelocity * optimal > v0 {
            return .good
        }
        else if angularVelocity * (optimal + falloff) > v1 {
            return .average
        }
        else {
            return .low
        }
    }
}

#if DEBUG
extension DGMGang {
    static func testGang(_ pilots: Int = 1) -> DGMGang {
        let gang = try! DGMGang()
        for _ in 0..<pilots {
            gang.add(.testCharacter())
        }
        return gang
    }
}

extension DGMCharacter {
    static func testCharacter() -> DGMCharacter {
        let pilot = try! DGMCharacter()
        pilot.ship = .testDominix()
        try! pilot.add(DGMImplant(typeID: 10211))
        try! pilot.add(DGMBooster(typeID: 10151))
        
        return pilot
    }
}

extension DGMShip {
    static func testDominix() -> DGMShip {
        let dominix = try! DGMShip(typeID: 645)
        try! dominix.add(DGMModule(typeID: 3154))
        try! dominix.add(DGMModule(typeID: 405))
        try! dominix.add(DGMModule(typeID: 3154))
        
        for _ in 0..<5 {
            try! dominix.add(DGMDrone(typeID: 2446))
        }
        return dominix
    }
}

#endif


extension DGMCharacter {
	class func url(account: Account) -> URL? {
		guard let uuid = account.uuid else {return nil}
		var components = URLComponents()
		components.scheme = Config.current.urlScheme
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
		components.scheme = Config.current.urlScheme
		components.host = "character"
		components.queryItems = [
			URLQueryItem(name: "level", value: String(level)),
			URLQueryItem(name: "name", value: NSLocalizedString("All Skills", comment: "") + " " + String(roman: level))
		]
		return components.url!
	}
	
	class func url(character: FitCharacter) -> URL? {
		guard let uuid = character.uuid else {return nil}
		var components = URLComponents()
		components.scheme = Config.current.urlScheme
		components.host = "character"
		components.queryItems = [
			URLQueryItem(name: "characterUUID", value: uuid),
			URLQueryItem(name: "name", value: character.name ?? "")
		]
		return components.url!
	}
	
	var account: NSFetchRequest<Account>? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let accountUUID = components.queryItems?.first(where: {$0.name == "accountUUID"})?.value else {return nil}
		let request = NSFetchRequest<Account>(entityName: "Account")
		request.predicate = (/\Account.uuid == accountUUID).predicate()
		request.fetchLimit = 1
		return request
	}
	
	var fitCharacter: NSFetchRequest<FitCharacter>? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let characterUUID = components.queryItems?.first(where: {$0.name == "characterUUID"})?.value else {return nil}
		let request = NSFetchRequest<FitCharacter>(entityName: "FitCharacter")
		request.predicate = (/\FitCharacter.uuid == characterUUID).predicate()
		request.fetchLimit = 1
		return request
	}
	
	var level: Int? {
		guard let url = url, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {return nil}
		guard let level = components.queryItems?.first(where: {$0.name == "level"})?.value else {return nil}
		return Int(level)
	}
	
	var url: URL? {
		return URL(string: name)
	}
}

enum DGMSkillLevels {
    case levelsMap([DGMTypeID: Int])
    case level(Int)
    
    static func fromAccount(_ account: Account, esi: ESI) -> AnyPublisher<DGMSkillLevels, AFError> {
        esi.characters.characterID(Int(account.characterID)).skills().get().map { skills in
            .levelsMap(Dictionary(skills.value.skills.map{(DGMTypeID($0.skillID), $0.trainedSkillLevel)}) {a, b in max(a, b)})
        }.eraseToAnyPublisher()
    }
}
