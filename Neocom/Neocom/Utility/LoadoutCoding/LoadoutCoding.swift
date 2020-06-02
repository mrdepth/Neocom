//
//  LoadoutCoding.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/7/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp

struct Ship: Codable, Hashable {
    struct Module: Codable, Hashable {
        var typeID: Int
        var count: Int = 1
        var id: Int? = nil
        var state: DGMModule.State = .active
        var charge: Item? = nil
        var socket: Int = -1
    }
    
    struct Drone: Codable, Hashable {
        var typeID: Int
        var count: Int = 1
        var id: Int? = nil
        var isActive: Bool = true
        var isKamikaze: Bool = false
        var squadronTag: Int = -1
    }
    
    struct Item: Codable, Hashable {
        var typeID: Int
        var count: Int
    }
    
    var typeID: Int
    var name: String?// = ""
    
    var modules: [DGMModule.Slot: [Module]]? = nil
    var drones: [Drone]? = nil
    var cargo: [Item]? = nil
    var implants: [Int]? = nil
    var boosters: [Int]? = nil
}

struct FleetConfiguration: Codable, Hashable {
    public var pilots: [Int: String]
    public var links: [Int: Int]
}

protocol LoadoutDecoder {
    func decode(from data: Data) throws -> Ship
}

protocol LoadoutEncoder {
    func encode(_ ship: Ship) throws -> Data
}

