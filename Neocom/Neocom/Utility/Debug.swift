//
//  Debug.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp
import CoreData
import Expressible
import EVEAPI

//1554561480

#if DEBUG
let oAuth2Token = try! JSONDecoder().decode(OAuth2Token.self, from: "{\"scopes\":[\"esi-calendar.respond_calendar_events.v1\",\"esi-calendar.read_calendar_events.v1\",\"esi-location.read_location.v1\",\"esi-location.read_ship_type.v1\",\"esi-mail.organize_mail.v1\",\"esi-mail.read_mail.v1\",\"esi-mail.send_mail.v1\",\"esi-skills.read_skills.v1\",\"esi-skills.read_skillqueue.v1\",\"esi-wallet.read_character_wallet.v1\",\"esi-search.search_structures.v1\",\"esi-clones.read_clones.v1\",\"esi-universe.read_structures.v1\",\"esi-killmails.read_killmails.v1\",\"esi-assets.read_assets.v1\",\"esi-planets.manage_planets.v1\",\"esi-fittings.read_fittings.v1\",\"esi-fittings.write_fittings.v1\",\"esi-markets.structure_markets.v1\",\"esi-characters.read_loyalty.v1\",\"esi-characters.read_standings.v1\",\"esi-industry.read_character_jobs.v1\",\"esi-markets.read_character_orders.v1\",\"esi-characters.read_blueprints.v1\",\"esi-contracts.read_character_contracts.v1\",\"esi-clones.read_implants.v1\",\"esi-killmails.read_corporation_killmails.v1\",\"esi-wallet.read_corporation_wallets.v1\",\"esi-corporations.read_divisions.v1\",\"esi-assets.read_corporation_assets.v1\",\"esi-corporations.read_blueprints.v1\",\"esi-contracts.read_corporation_contracts.v1\",\"esi-industry.read_corporation_jobs.v1\",\"esi-markets.read_corporation_orders.v1\"],\"characterID\":1554561480,\"characterName\":\"Artem Valiant\",\"refreshToken\":\"1ETZtnu7-ic9k1vE-rhBGhC76QQ5VMCbzKU3bIid32BgS00pgtOJPozLGaUSociDGpnyzpPLMapm3bOvbjERA0wUYPvNMmr77HPdrJtFh09kII7VN5SxvaVKYO9PkokE4GByoWY8ExmiQadXLmy5yzzJx4BkvI4mobv82MG7LZzbil8n4rH23bSOnVQGOuzBAgZflvwAEqdKw1y8Gm8PAlnoDjnb_B0LM2bBrvYz7zY1\",\"tokenType\":\"Bearer\",\"expiresOn\":556720099.51404095,\"accessToken\":\"YWm0r6Z1svq2Jido_8zHQ5bIo6TE72CmvI-TR8-9_VLgZd6plowi6r9OzQyC4_DzIImjAbhyRGSMz3Hv_6Z6kg2\",\"realm\":\"esi\"}".data(using: .utf8)!)
#endif


extension SDEInvType {
    class var dominix: SDEInvType {
        return try! AppDelegate.sharedDelegate.persistentContainer.viewContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == 645).first()!
    }
}

extension DGMGang {
    static func testGang(_ pilots: Int = 1) -> DGMGang {
        let gang = try! DGMGang()
        for _ in 0..<pilots {
            gang.add(.testCharacter())
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

extension Loadout {
    static func testLoadouts() -> [Loadout] {
        _ = try? AppDelegate.sharedDelegate.persistentContainer.viewContext.from(Loadout.self).delete()
        
        let loadout1 = Loadout(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        loadout1.name = "Test Loadout"
        loadout1.typeID = 645

        let loadout2 = Loadout(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        loadout2.name = "Test Loadout2"
        loadout2.typeID = 645
        
        try? AppDelegate.sharedDelegate.persistentContainer.viewContext.save()
        return [loadout1, loadout2]
    }
}

extension DGMPlanet {
    static func testPlanet() -> DGMPlanet {
        let planet = try! ESI.jsonDecoder.decode(ESI.Planets.self, from: NSDataAsset(name: "planetsList")!.data)[0]
        let info = try! ESI.jsonDecoder.decode(ESI.PlanetInfo.self, from: NSDataAsset(name: "planetInfo")!.data)
        return try! DGMPlanet(planet: planet, info: info)
    }
}

extension Contact {
    static func testContact() -> Contact {
        testContact(contactID: 1554561480, name: "Artem Valiant")
    }
    
    static func testContact(contactID: Int64, name: String) -> Contact {
        let contact = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: AppDelegate.sharedDelegate.persistentContainer.viewContext)!, insertInto: nil)
        contact.name = name
        contact.contactID = contactID
        contact.category = ESI.RecipientType.character.rawValue
        return contact
    }
}
