//
//  ESI+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/26/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

extension ESI {
    typealias SkillQueueItem = ESI.Characters.CharacterID.Skillqueue.Success
    typealias Skill = ESI.Characters.CharacterID.Skills.Skill
    typealias CharacterAttributes = ESI.Characters.CharacterID.Attributes.Success
    typealias CharacterSkills = ESI.Characters.CharacterID.Skills.Success
    typealias Ship = ESI.Characters.CharacterID.Ship.Success
    typealias CharacterInfo = ESI.Characters.CharacterID.Success
    typealias CorporationInfo = ESI.Corporations.CorporationID.Success
    typealias AllianceInfo = ESI.Alliances.AllianceID.Success
    typealias MarketHistoryItem = ESI.Markets.RegionID.History.Success
    typealias MarketPrice = ESI.Markets.Prices.Success
    typealias ItemName = ESI.Universe.Names.Success
    typealias StructureInfo = ESI.Universe.Structures.StructureID.Success
    typealias TypeMarketOrder = ESI.Markets.RegionID.Orders.Success
    typealias Attributes = ESI.Characters.CharacterID.Attributes.Success
    typealias Implants = [Int]
    typealias Clones = ESI.Characters.CharacterID.Clones.Success
    
    convenience init(token: OAuth2Token) {
        self.init(token: token, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey)
    }
}
