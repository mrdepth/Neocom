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
let testOAuth2Token = try! JSONDecoder().decode(OAuth2Token.self, from: "{\"scopes\":[\"esi-calendar.respond_calendar_events.v1\",\"esi-calendar.read_calendar_events.v1\",\"esi-location.read_location.v1\",\"esi-location.read_ship_type.v1\",\"esi-mail.organize_mail.v1\",\"esi-mail.read_mail.v1\",\"esi-mail.send_mail.v1\",\"esi-skills.read_skills.v1\",\"esi-skills.read_skillqueue.v1\",\"esi-wallet.read_character_wallet.v1\",\"esi-search.search_structures.v1\",\"esi-clones.read_clones.v1\",\"esi-universe.read_structures.v1\",\"esi-killmails.read_killmails.v1\",\"esi-assets.read_assets.v1\",\"esi-planets.manage_planets.v1\",\"esi-fittings.read_fittings.v1\",\"esi-fittings.write_fittings.v1\",\"esi-markets.structure_markets.v1\",\"esi-characters.read_loyalty.v1\",\"esi-characters.read_standings.v1\",\"esi-industry.read_character_jobs.v1\",\"esi-markets.read_character_orders.v1\",\"esi-characters.read_blueprints.v1\",\"esi-contracts.read_character_contracts.v1\",\"esi-clones.read_implants.v1\",\"esi-killmails.read_corporation_killmails.v1\",\"esi-wallet.read_corporation_wallets.v1\",\"esi-corporations.read_divisions.v1\",\"esi-assets.read_corporation_assets.v1\",\"esi-corporations.read_blueprints.v1\",\"esi-contracts.read_corporation_contracts.v1\",\"esi-industry.read_corporation_jobs.v1\",\"esi-markets.read_corporation_orders.v1\"],\"characterID\":1554561480,\"characterName\":\"Artem Valiant\",\"refreshToken\":\"1ETZtnu7-ic9k1vE-rhBGhC76QQ5VMCbzKU3bIid32BgS00pgtOJPozLGaUSociDGpnyzpPLMapm3bOvbjERA0wUYPvNMmr77HPdrJtFh09kII7VN5SxvaVKYO9PkokE4GByoWY8ExmiQadXLmy5yzzJx4BkvI4mobv82MG7LZzbil8n4rH23bSOnVQGOuzBAgZflvwAEqdKw1y8Gm8PAlnoDjnb_B0LM2bBrvYz7zY\",\"tokenType\":\"Bearer\",\"expiresOn\":556720099.51404095,\"accessToken\":\"YWm0r6Z1svq2Jido_8zHQ5bIo6TE72CmvI-TR8-9_VLgZd6plowi6r9OzQyC4_DzIImjAbhyRGSMz3Hv_6Z6kg2\",\"realm\":\"esi\"}".data(using: .utf8)!)

let testOAuth2Token2 = try! JSONDecoder().decode(OAuth2Token.self, from: "{\"scopes\":[\"esi-calendar.respond_calendar_events.v1\",\"esi-calendar.read_calendar_events.v1\",\"esi-location.read_location.v1\",\"esi-location.read_ship_type.v1\",\"esi-mail.organize_mail.v1\",\"esi-mail.read_mail.v1\",\"esi-mail.send_mail.v1\",\"esi-skills.read_skills.v1\",\"esi-skills.read_skillqueue.v1\",\"esi-wallet.read_character_wallet.v1\",\"esi-search.search_structures.v1\",\"esi-clones.read_clones.v1\",\"esi-characters.read_contacts.v1\",\"esi-universe.read_structures.v1\",\"esi-bookmarks.read_character_bookmarks.v1\",\"esi-killmails.read_killmails.v1\",\"esi-corporations.read_corporation_membership.v1\",\"esi-assets.read_assets.v1\",\"esi-planets.manage_planets.v1\",\"esi-fleets.read_fleet.v1\",\"esi-fleets.write_fleet.v1\",\"esi-ui.open_window.v1\",\"esi-ui.write_waypoint.v1\",\"esi-characters.write_contacts.v1\",\"esi-fittings.read_fittings.v1\",\"esi-fittings.write_fittings.v1\",\"esi-markets.structure_markets.v1\",\"esi-corporations.read_structures.v1\",\"esi-characters.read_loyalty.v1\",\"esi-characters.read_opportunities.v1\",\"esi-characters.read_medals.v1\",\"esi-characters.read_standings.v1\",\"esi-characters.read_agents_research.v1\",\"esi-industry.read_character_jobs.v1\",\"esi-markets.read_character_orders.v1\",\"esi-characters.read_blueprints.v1\",\"esi-characters.read_corporation_roles.v1\",\"esi-location.read_online.v1\",\"esi-contracts.read_character_contracts.v1\",\"esi-clones.read_implants.v1\",\"esi-characters.read_fatigue.v1\",\"esi-killmails.read_corporation_killmails.v1\",\"esi-corporations.track_members.v1\",\"esi-wallet.read_corporation_wallets.v1\",\"esi-characters.read_notifications.v1\",\"esi-corporations.read_divisions.v1\",\"esi-corporations.read_contacts.v1\",\"esi-assets.read_corporation_assets.v1\",\"esi-corporations.read_titles.v1\",\"esi-corporations.read_blueprints.v1\",\"esi-bookmarks.read_corporation_bookmarks.v1\",\"esi-contracts.read_corporation_contracts.v1\",\"esi-corporations.read_standings.v1\",\"esi-corporations.read_starbases.v1\",\"esi-industry.read_corporation_jobs.v1\",\"esi-markets.read_corporation_orders.v1\",\"esi-corporations.read_container_logs.v1\",\"esi-industry.read_character_mining.v1\",\"esi-industry.read_corporation_mining.v1\",\"esi-planets.read_customs_offices.v1\",\"esi-corporations.read_facilities.v1\",\"esi-corporations.read_medals.v1\",\"esi-characters.read_titles.v1\",\"esi-alliances.read_contacts.v1\",\"esi-characters.read_fw_stats.v1\",\"esi-corporations.read_fw_stats.v1\",\"esi-characterstats.read.v1\"],\"characterID\":90553786,\"characterName\":\"Po\'kupatel Boloskarl\",\"refreshToken\":\"FmBz8VdLAn9HRG74UnOeOoQt6Q-BVl3YqH-7Pt6tEL7dSzPTYjHZxgQ8GA0zg0KNNvqk4mOZWkX9BqS9HvPFqp_nXem8FYNUqkj45ejkHHTgGzjKimLW7ha8UwrToHHCJGbV5YJcmdHbQvBRNtY-Cg7ECnesFxOBpuMCgKdpqfM9Llie4vyMg-eNTdNMXG5uFHvA_py-qm7lcaI4o-mz-fLHTCug_evJ9SCpOg3nETGMj6Qmp_1-nj5-YGMYfnWvQtQb_HF2K4icx-vezXUNjHS3Y2VPIRlJqGPUR-MHLl8odw5313ozZrrUFD68MkYXXYJOnOza97Xw4a7XMFgVlMwHwYI936qIDtlBCsQ7sY5SuQSMaAEC4IClkx8xHv6Sway4dFw-garj5dpKgzR3hQ\",\"tokenType\":\"Bearer\",\"expiresOn\":608318460.16410697,\"accessToken\":\"1|CfDJ8Hj9X4L\\/huFJpslTkv3swZMol+qO6KXHVWXDDS8ieIcy6ELFv\\/5Vu6eAYU0HZipsNn6zegVPUEvMTgG4PIx6WQf+fy88P1dVbmbcbalGnD3NXQ+lrgX1ca09rPhxCz0K7S8vIz3OlFYybxyJjvIZmoegn\\/2+PKRA4KjKzmpidusH\",\"realm\":\"esi\"}".data(using: .utf8)!)
#endif


extension SDEInvType {
    class var dominix: SDEInvType {
        return try! Storage.testStorage.persistentContainer.viewContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == 645).first()!
    }
    
    class var gallenteCarrier: SDEInvType {
        return try! Storage.testStorage.persistentContainer.viewContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == 24313).first()!
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
        try! dominix.add(DGMCargo(typeID: 3154))
        for _ in 0..<5 {
            try! dominix.add(DGMDrone(typeID: 2446))
        }
        return dominix
    }
    
    static func testNyx() -> DGMShip {
        let nyx = try! DGMShip(typeID: 23913)
        
        for _ in 0..<5 {
            try! nyx.add(DGMDrone(typeID: 40362))
            try! nyx.add(DGMDrone(typeID: 40557))
        }
        return nyx
    }
    
}

extension Fleet {
    static func testFleet() -> Fleet {
        _ = try? Storage.testStorage.persistentContainer.viewContext.from(Fleet.self).delete()
        let fleet = Fleet(context: Storage.testStorage.persistentContainer.viewContext)
        fleet.name = "Fleet"
        Loadout.testLoadouts().forEach {
            $0.addToFleets(fleet)
        }
        return fleet
    }
}

extension Loadout {
    static func testLoadouts() -> [Loadout] {
        _ = try? Storage.testStorage.persistentContainer.viewContext.from(Loadout.self).delete()
        
        let loadout1 = Loadout(context: Storage.testStorage.persistentContainer.viewContext)
        loadout1.name = "Test Loadout"
        loadout1.typeID = 645

        let loadout2 = Loadout(context: Storage.testStorage.persistentContainer.viewContext)
        loadout2.name = "Test Loadout2"
        loadout2.typeID = 645
        
        try? Storage.testStorage.persistentContainer.viewContext.save()
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
        let contact = Contact(entity: NSEntityDescription.entity(forEntityName: "Contact", in: Storage.testStorage.persistentContainer.viewContext)!, insertInto: nil)
        contact.name = name
        contact.contactID = contactID
        contact.category = ESI.RecipientType.character.rawValue
        return contact
    }
}

extension DGMStructure {
    static func testKeepstar() -> DGMStructure {
        let structure = try! DGMStructure(typeID: 35834)
        try! structure.add(DGMModule(typeID: 35928))
        try! structure.add(DGMModule(typeID: 35892))
        try! structure.add(DGMModule(typeID: 35881))
        return structure
    }
}


#if DEBUG

extension Storage {
    static var testStorage = Storage()
}

//extension AppDelegate {
//    func migrate() {
//        let container = NSPersistentCloudKitContainer(name: "Neocom", managedObjectModel: managedObjectModel)
//        let sdeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("SDE.sqlite")
//        try? FileManager.default.removeItem(at: sdeURL)
//        try? FileManager.default.copyItem(at: Bundle.main.url(forResource: "SDE", withExtension: "sqlite")!, to: sdeURL)
//        let sde = NSPersistentStoreDescription(url: sdeURL)
//        sde.configuration = "SDE"
//        sde.setValue("DELETE" as NSString, forPragmaNamed: "journal_mode")
//        sde.shouldMigrateStoreAutomatically = true
//        sde.shouldInferMappingModelAutomatically = true
//        
//        let storage = NSPersistentStoreDescription(url: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!).appendingPathComponent("store.sqlite"))
//        storage.configuration = "Storage"
//        storage.shouldInferMappingModelAutomatically = true
//        storage.shouldInferMappingModelAutomatically = true
//        container.persistentStoreDescriptions = [sde, storage]
//        container.loadPersistentStores { (_, error) in
//            if let error = error {
//                print(error)
//            }
//        }
//    }
//}

extension Account {
    static var testingAccount: Account? = {
        if let account = try? Storage.testStorage.persistentContainer.viewContext.from(Account.self).first() {
            if account.uuid == nil {
                account.uuid = "1"
                try? Storage.testStorage.persistentContainer.viewContext.save()
            }
            return account
        }
        else {
            let account = Account(token: testOAuth2Token, context: Storage.testStorage.persistentContainer.viewContext)
            account.uuid = "1"
            try? Storage.testStorage.persistentContainer.viewContext.save()
            return account
        }
    }()
}

extension ServicesViewModifier {
    static func testModifier() -> ServicesViewModifier {
        return ServicesViewModifier(managedObjectContext: Storage.testStorage.persistentContainer.viewContext,
                                    backgroundManagedObjectContext: Storage.testStorage.persistentContainer.newBackgroundContext(),
                                    sharedState: SharedState.testState())
    }
}
extension SharedState {
    class func testState() -> SharedState {
        let account = Account.testingAccount
        UserDefault(wrappedValue: String?.none, key: .activeAccountID).wrappedValue = account?.uuid
        return SharedState(managedObjectContext: Storage.testStorage.persistentContainer.viewContext)
    }
}

#endif
