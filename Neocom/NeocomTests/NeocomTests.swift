//
//  NeocomTests.swift
//  NeocomTests
//
//  Created by Artem Shimanski on 5/31/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import Neocom
import Dgmpp

private let dominixDNA = "645:448;1:11269;2:25894;3:2024;1:527;1:3122;6:12084;1:11325;4:23473;5:2446;6:12791;400:12787;3200:11287;2:573_;1::"

private let dominixEFT = """
[Dominix, Dominix бластерный]
Energized Adaptive Nano Membrane II
Energized Adaptive Nano Membrane II
1600mm Rolled Tungsten Compact Plates
1600mm Rolled Tungsten Compact Plates
1600mm Rolled Tungsten Compact Plates
1600mm Rolled Tungsten Compact Plates

Warp Scrambler II
Medium Capacitor Booster II
Stasis Webifier II
500MN Microwarpdrive II

Electron Blaster Cannon II
Electron Blaster Cannon II
Electron Blaster Cannon II
Electron Blaster Cannon II
Electron Blaster Cannon II
Electron Blaster Cannon II

Large Trimark Armor Pump I
Large Trimark Armor Pump I
Large Trimark Armor Pump I



Wasp EC-900 x5
Ogre II x6

Void L x400
Null L x3200
Cap Booster 400 x2
Neutron Blaster Cannon I x1

"""

class NeocomTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPlainTextCoding1() throws {
        let context = AppDelegate.sharedDelegate.storage.persistentContainer.viewContext
        let ship = DGMShip.testDominix()
        ship.name = "Ship Name"
        let loadoutA = ship.loadout
        let data = try LoadoutPlainTextEncoder(managedObjectContext: context).encode(loadoutA)
        let loadoutB = try LoadoutPlainTextDecoder(managedObjectContext: context).decode(from: data)

        XCTAssertTrue(areEquivalent(loadoutA, loadoutB))
    }

    func testPlainTextCoding2() throws {
        let context = AppDelegate.sharedDelegate.storage.persistentContainer.viewContext
        let loadoutA = try LoadoutPlainTextDecoder(managedObjectContext: context).decode(from: dominixEFT.data(using: .utf8)!)
        let data = try LoadoutPlainTextEncoder(managedObjectContext: context).encode(loadoutA)
        let loadoutB = try LoadoutPlainTextDecoder(managedObjectContext: context).decode(from: data)
        
        XCTAssertEqual(dominixEFT.components(separatedBy: "\n").sorted(), String(data: data, encoding: .utf8)!.components(separatedBy: "\n").sorted())
        XCTAssertTrue(areEquivalent(loadoutA, loadoutB))
    }
    
    func testDNACoding() throws {
        let context = AppDelegate.sharedDelegate.storage.persistentContainer.viewContext
        let loadoutA = try LoadoutPlainTextDecoder(managedObjectContext: context).decode(from: dominixEFT.data(using: .utf8)!)
        var loadoutB = try DNALoadoutDecoder(managedObjectContext: context).decode(from: dominixDNA.data(using: .utf8)!)
        loadoutB.name = loadoutA.name
        XCTAssertTrue(areEquivalent(loadoutA, loadoutB))
    }

    private func areEquivalent(_ lhs: Ship, _ rhs: Ship) -> Bool {
        let modulesA = lhs.modules?.mapValues{ Dictionary(($0.map{($0.typeID, $0.count)})) { (a, b) in a + b }  }
        let modulesB = rhs.modules?.mapValues{ Dictionary(($0.map{($0.typeID, $0.count)})) { (a, b) in a + b }  }
        
        let dronesA = lhs.drones.map{ drones in Dictionary(drones.map{($0.typeID, $0.count)}) { (a, b) in a + b }}
        let dronesB = rhs.drones.map{ drones in Dictionary(drones.map{($0.typeID, $0.count)}) { (a, b) in a + b }}

        let cargoA = lhs.cargo.map{ cargo in Dictionary(cargo.map{($0.typeID, $0.count)}) { (a, b) in a + b }}
        let cargoB = rhs.cargo.map{ cargo in Dictionary(cargo.map{($0.typeID, $0.count)}) { (a, b) in a + b }}

        return lhs.typeID == rhs.typeID && lhs.name == rhs.name && modulesA == modulesB && dronesA == dronesB && cargoA == cargoB
    }

}
/*
 [Dominix, *Ship Name]


 Ion Blaster Cannon II
 'Micro' Remote Shield Booster
 Ion Blaster Cannon II




 Ogre II x5

 Ion Blaster Cannon II x1


 */
