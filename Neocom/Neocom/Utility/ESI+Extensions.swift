//
//  ESI+Extensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/26/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import SwiftUI
import CoreData
import Expressible

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
    typealias Assets = [ESI.Characters.CharacterID.Assets.Success]
    typealias LocationFlag = ESI.Characters.CharacterID.Assets.LocationFlag
    typealias CorporationLocationFlag = ESI.Corporations.CorporationID.LocationFlag
    typealias WalletJournal = [ESI.Characters.CharacterID.Wallet.Journal.Success]
    typealias WalletTransactions = [ESI.Characters.CharacterID.Wallet.Transactions.Success]
    typealias RecipientType = ESI.Characters.CharacterID.Mail.RecipientType
    typealias MarketOrders = [ESI.Characters.CharacterID.Orders.Success]
    typealias IndustryJobs = [ESI.Characters.CharacterID.Industry.Jobs.Success]
    typealias IndustryJobStatus = ESI.Characters.CharacterID.Industry.Jobs.Status
    typealias PersonalContracts = [ESI.Characters.CharacterID.Contracts.Success]
    typealias ContractStatus = ESI.Characters.CharacterID.Contracts.Status
    typealias ContractItems = [ESI.Characters.CharacterID.Contracts.ContractID.Items.Success]
    typealias ContractBids = [ESI.Characters.CharacterID.Contracts.ContractID.Bids.Success]
    typealias MailLabels = ESI.Characters.CharacterID.Mail.Labels.Success
    typealias MailLabel = ESI.Characters.CharacterID.Mail.Labels.Label
    typealias MailHeaders = [ESI.Characters.CharacterID.Mail.Success]
    typealias MailBody = ESI.Characters.CharacterID.Mail.MailID.Success
    typealias Mail = ESI.Characters.CharacterID.Mail.Mail
    typealias Recipient = ESI.Characters.CharacterID.Mail.Recipient
    typealias Calendar = [ESI.Characters.CharacterID.Calendar.Success]
    typealias Event = ESI.Characters.CharacterID.Calendar.EventID.Success
    typealias LoyaltyPoints = [ESI.Characters.CharacterID.Loyalty.Points.Success]
    typealias LoyaltyOffers = [ESI.Loyalty.Stores.CorporationID.Offers.Success]
    typealias LoyaltyOfferRequirement = ESI.Loyalty.Stores.CorporationID.Offers.RequiredItem
    typealias ServerStatus = ESI.Status.Success
    typealias Incursion = ESI.Incursions.Success
    typealias Planets = [ESI.Characters.CharacterID.Planets.Success]
    typealias PlanetInfo = ESI.Characters.CharacterID.Planets.PlanetID.Success
    typealias Killmail = ESI.Killmails.KillmailID.KillmailHash.Success
    typealias Attacker = ESI.Killmails.KillmailID.KillmailHash.Attacker
    typealias KillmailHash = ESI.Characters.CharacterID.Killmails.Recent.Success
    typealias Fittings = [ESI.Characters.CharacterID.Fittings.Success]
    typealias MutableFitting = ESI.Characters.CharacterID.Fittings.Fitting
    typealias FittingItem = ESI.Characters.CharacterID.Fittings.Item
    typealias FittingItemFlag = ESI.Characters.CharacterID.Fittings.Flag
    
    convenience init(token: OAuth2Token) {
        self.init(token: token, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey)
    }
}

protocol FittingFlag {
    var isDrone: Bool {get}
    var isCargo: Bool {get}
}

extension ESI.LocationFlag: FittingFlag {
    var isDrone: Bool {
        switch self {
        case .droneBay, .fighterBay, .fighterTube0, .fighterTube1, .fighterTube2, .fighterTube3, .fighterTube4:
            return true
        default:
            return false
        }
    }
    
    var isCargo: Bool {
        switch self {
        case .cargo:
            return true
        default:
            return false
        }
    }
}

extension ESI.FittingItemFlag: FittingFlag {
    var isDrone: Bool {
        switch self {
        case .droneBay, .fighterBay:
            return true
        default:
            return false
        }
    }
    
    var isCargo: Bool {
        switch self {
        case .cargo:
            return true
        default:
            return false
        }
    }
}

extension ESI.Characters.CharacterID.Wallet.Journal.RefType {
    var title: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

extension ESI.Characters.CharacterID.Industry.Jobs.Success {
    var currentStatus: ESI.IndustryJobStatus {
        switch status {
        case .active:
            return endDate < Date() ? .ready : status
        default:
            return status
        }
    }
}

extension ESI.Characters.CharacterID.Contracts.Success {
    var currentStatus: ESI.ContractStatus {
        switch status {
        case .outstanding, .inProgress:
            return dateExpired < Date() ? .finished : status
        default:
            return status
        }
    }
    var isOpen: Bool {
        return dateExpired > Date() && (status == .outstanding || status == .inProgress)
    }
    
    var endDate: Date {
        return dateCompleted ?? {
            guard let date = dateAccepted, let duration = daysToComplete else {return nil}
            return date.addingTimeInterval(TimeInterval(duration) * 24 * 3600)
            }() ?? dateExpired
    }
}


extension ESI.ContractStatus {
    var title: String {
        switch self {
        case .outstanding:
            return NSLocalizedString("Outstanding", comment: "")
        case .inProgress:
            return NSLocalizedString("In Progress", comment: "")
        case .cancelled:
            return NSLocalizedString("Cancelled", comment: "")
        case .deleted:
            return NSLocalizedString("Deleted", comment: "")
        case .failed:
            return NSLocalizedString("Failed", comment: "")
        case .finished, .finishedContractor, .finishedIssuer:
            return NSLocalizedString("Finished", comment: "")
        case .rejected:
            return NSLocalizedString("Rejected", comment: "")
        case .reversed:
            return NSLocalizedString("Reversed", comment: "")
        }
    }
    
}

extension ESI.Characters.ValueType {
    var title: String {
        switch self {
        case .auction:
            return NSLocalizedString("Auction", comment: "")
        case .courier:
            return NSLocalizedString("Courier", comment: "")
        case .itemExchange:
            return NSLocalizedString("Item Exchange", comment: "")
        case .loan:
            return NSLocalizedString("Loan", comment: "")
        case .unknown:
            return NSLocalizedString("Unknown", comment: "")
        }
    }
}

extension ESI.Characters.Availability {
    var title: String {
        switch self {
        case .alliance:
            return NSLocalizedString("Alliance", comment: "")
        case .corporation:
            return NSLocalizedString("Corporation", comment: "")
        case .personal:
            return NSLocalizedString("Personal", comment: "")
        case .public:
            return NSLocalizedString("Public", comment: "")
        }
    }
}

extension ESI.Incursions.State {
    var title: String {
        switch self {
        case .established:
            return NSLocalizedString("Established", comment: "")
        case .mobilizing:
            return NSLocalizedString("Mobilizing", comment: "")
        case .withdrawing:
            return NSLocalizedString("Withdrawing", comment: "")
        }
    }
    
}

public enum AssetSlot: Int, Hashable {
    case hi
    case med
    case low
    case rig
    case subsystem
    case drone
    case cargo
    case implant
    
    var title: String {
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
        case .drone:
            return NSLocalizedString("Drones", comment: "")
        case .cargo:
            return NSLocalizedString("Cargo", comment: "")
        case .implant:
            return NSLocalizedString("Implant", comment: "")
        }
    }
    
//    var image: UIImage {
//        switch self {
//        case .hi:
//            return #imageLiteral(resourceName: "slotHigh")
//        case .med:
//            return #imageLiteral(resourceName: "slotMed")
//        case .low:
//            return #imageLiteral(resourceName: "slotLow")
//        case .rig:
//            return #imageLiteral(resourceName: "slotRig")
//        case .subsystem:
//            return #imageLiteral(resourceName: "slotSubsystem")
//        case .drone:
//            return #imageLiteral(resourceName: "drone")
//        case .cargo:
//            return #imageLiteral(resourceName: "cargoBay")
//        case .implant:
//            return #imageLiteral(resourceName: "implant.pdf")
//        }
//    }
}

extension ESI.LocationFlag {
    var slot: AssetSlot? {
        switch self {
        case .hiSlot0, .hiSlot1, .hiSlot2, .hiSlot3, .hiSlot4, .hiSlot5, .hiSlot6, .hiSlot7:
            return .hi
        case .medSlot0, .medSlot1, .medSlot2, .medSlot3, .medSlot4, .medSlot5, .medSlot6, .medSlot7:
            return .med
        case .loSlot0, .loSlot1, .loSlot2, .loSlot3, .loSlot4, .loSlot5, .loSlot6, .loSlot7:
            return .low
        case .rigSlot0, .rigSlot1, .rigSlot2, .rigSlot3, .rigSlot4, .rigSlot5, .rigSlot6, .rigSlot7:
            return .rig
        case .subSystemSlot0, .subSystemSlot1, .subSystemSlot2, .subSystemSlot3, .subSystemSlot4, .subSystemSlot5, .subSystemSlot6, .subSystemSlot7:
            return .subsystem
        case .droneBay, .fighterBay, .fighterTube0, .fighterTube1, .fighterTube2, .fighterTube3, .fighterTube4:
            return .drone
        case .cargo:
            return .cargo
        case .implant:
            return .implant
        default:
            return nil
        }

    }
}

extension ESI.LocationFlag {
    init?(rawValue: Int) {
        let result: ESI.LocationFlag?
        switch rawValue {
        case 0:
            result = ESI.LocationFlag(rawValue: "None")
        case 1:
            result = ESI.LocationFlag(rawValue: "Wallet")
        case 2:
            result = ESI.LocationFlag(rawValue: "Factory")
        case 3:
            result = ESI.LocationFlag(rawValue: "Wardrobe")
        case 4:
            result = ESI.LocationFlag(rawValue: "Hangar")
        case 5:
            result = ESI.LocationFlag(rawValue: "Cargo")
        case 6:
            result = ESI.LocationFlag(rawValue: "Briefcase")
        case 7:
            result = ESI.LocationFlag(rawValue: "Skill")
        case 8:
            result = ESI.LocationFlag(rawValue: "Reward")
        case 9:
            result = ESI.LocationFlag(rawValue: "Connected")
        case 10:
            result = ESI.LocationFlag(rawValue: "Disconnected")
        case 11:
            result = ESI.LocationFlag(rawValue: "LoSlot0")
        case 12:
            result = ESI.LocationFlag(rawValue: "LoSlot1")
        case 13:
            result = ESI.LocationFlag(rawValue: "LoSlot2")
        case 14:
            result = ESI.LocationFlag(rawValue: "LoSlot3")
        case 15:
            result = ESI.LocationFlag(rawValue: "LoSlot4")
        case 16:
            result = ESI.LocationFlag(rawValue: "LoSlot5")
        case 17:
            result = ESI.LocationFlag(rawValue: "LoSlot6")
        case 18:
            result = ESI.LocationFlag(rawValue: "LoSlot7")
        case 19:
            result = ESI.LocationFlag(rawValue: "MedSlot0")
        case 20:
            result = ESI.LocationFlag(rawValue: "MedSlot1")
        case 21:
            result = ESI.LocationFlag(rawValue: "MedSlot2")
        case 22:
            result = ESI.LocationFlag(rawValue: "MedSlot3")
        case 23:
            result = ESI.LocationFlag(rawValue: "MedSlot4")
        case 24:
            result = ESI.LocationFlag(rawValue: "MedSlot5")
        case 25:
            result = ESI.LocationFlag(rawValue: "MedSlot6")
        case 26:
            result = ESI.LocationFlag(rawValue: "MedSlot7")
        case 27:
            result = ESI.LocationFlag(rawValue: "HiSlot0")
        case 28:
            result = ESI.LocationFlag(rawValue: "HiSlot1")
        case 29:
            result = ESI.LocationFlag(rawValue: "HiSlot2")
        case 30:
            result = ESI.LocationFlag(rawValue: "HiSlot3")
        case 31:
            result = ESI.LocationFlag(rawValue: "HiSlot4")
        case 32:
            result = ESI.LocationFlag(rawValue: "HiSlot5")
        case 33:
            result = ESI.LocationFlag(rawValue: "HiSlot6")
        case 34:
            result = ESI.LocationFlag(rawValue: "HiSlot7")
        case 35:
            result = ESI.LocationFlag(rawValue: "Fixed Slot")
        case 36:
            result = ESI.LocationFlag(rawValue: "AssetSafety")
        case 40:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot1")
        case 41:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot2")
        case 42:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot3")
        case 43:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot4")
        case 44:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot5")
        case 45:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot6")
        case 46:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot7")
        case 47:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot8")
        case 48:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot9")
        case 49:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot10")
        case 50:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot11")
        case 51:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot12")
        case 52:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot13")
        case 53:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot14")
        case 54:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot15")
        case 55:
            result = ESI.LocationFlag(rawValue: "PromenadeSlot16")
        case 56:
            result = ESI.LocationFlag(rawValue: "Capsule")
        case 57:
            result = ESI.LocationFlag(rawValue: "Pilot")
        case 58:
            result = ESI.LocationFlag(rawValue: "Passenger")
        case 59:
            result = ESI.LocationFlag(rawValue: "Boarding Gate")
        case 60:
            result = ESI.LocationFlag(rawValue: "Crew")
        case 61:
            result = ESI.LocationFlag(rawValue: "Skill In Training")
        case 62:
            result = ESI.LocationFlag(rawValue: "CorpMarket")
        case 63:
            result = ESI.LocationFlag(rawValue: "Locked")
        case 64:
            result = ESI.LocationFlag(rawValue: "Unlocked")
        case 70:
            result = ESI.LocationFlag(rawValue: "Office Slot 1")
        case 71:
            result = ESI.LocationFlag(rawValue: "Office Slot 2")
        case 72:
            result = ESI.LocationFlag(rawValue: "Office Slot 3")
        case 73:
            result = ESI.LocationFlag(rawValue: "Office Slot 4")
        case 74:
            result = ESI.LocationFlag(rawValue: "Office Slot 5")
        case 75:
            result = ESI.LocationFlag(rawValue: "Office Slot 6")
        case 76:
            result = ESI.LocationFlag(rawValue: "Office Slot 7")
        case 77:
            result = ESI.LocationFlag(rawValue: "Office Slot 8")
        case 78:
            result = ESI.LocationFlag(rawValue: "Office Slot 9")
        case 79:
            result = ESI.LocationFlag(rawValue: "Office Slot 10")
        case 80:
            result = ESI.LocationFlag(rawValue: "Office Slot 11")
        case 81:
            result = ESI.LocationFlag(rawValue: "Office Slot 12")
        case 82:
            result = ESI.LocationFlag(rawValue: "Office Slot 13")
        case 83:
            result = ESI.LocationFlag(rawValue: "Office Slot 14")
        case 84:
            result = ESI.LocationFlag(rawValue: "Office Slot 15")
        case 85:
            result = ESI.LocationFlag(rawValue: "Office Slot 16")
        case 86:
            result = ESI.LocationFlag(rawValue: "Bonus")
        case 87:
            result = ESI.LocationFlag(rawValue: "DroneBay")
        case 88:
            result = ESI.LocationFlag(rawValue: "Booster")
        case 89:
            result = ESI.LocationFlag(rawValue: "Implant")
        case 90:
            result = ESI.LocationFlag(rawValue: "ShipHangar")
        case 91:
            result = ESI.LocationFlag(rawValue: "ShipOffline")
        case 92:
            result = ESI.LocationFlag(rawValue: "RigSlot0")
        case 93:
            result = ESI.LocationFlag(rawValue: "RigSlot1")
        case 94:
            result = ESI.LocationFlag(rawValue: "RigSlot2")
        case 95:
            result = ESI.LocationFlag(rawValue: "RigSlot3")
        case 96:
            result = ESI.LocationFlag(rawValue: "RigSlot4")
        case 97:
            result = ESI.LocationFlag(rawValue: "RigSlot5")
        case 98:
            result = ESI.LocationFlag(rawValue: "RigSlot6")
        case 99:
            result = ESI.LocationFlag(rawValue: "RigSlot7")
        case 100:
            result = ESI.LocationFlag(rawValue: "Factory Operation")
        case 115:
            result = ESI.LocationFlag(rawValue: "CorpSAG1")
        case 116:
            result = ESI.LocationFlag(rawValue: "CorpSAG2")
        case 117:
            result = ESI.LocationFlag(rawValue: "CorpSAG3")
        case 118:
            result = ESI.LocationFlag(rawValue: "CorpSAG4")
        case 119:
            result = ESI.LocationFlag(rawValue: "CorpSAG5")
        case 120:
            result = ESI.LocationFlag(rawValue: "CorpSAG6")
        case 121:
            result = ESI.LocationFlag(rawValue: "CorpSAG7")
        case 122:
            result = ESI.LocationFlag(rawValue: "SecondaryStorage")
        case 123:
            result = ESI.LocationFlag(rawValue: "CaptainsQuarters")
        case 124:
            result = ESI.LocationFlag(rawValue: "Wis Promenade")
        case 125:
            result = ESI.LocationFlag(rawValue: "SubSystem0")
        case 126:
            result = ESI.LocationFlag(rawValue: "SubSystem1")
        case 127:
            result = ESI.LocationFlag(rawValue: "SubSystem2")
        case 128:
            result = ESI.LocationFlag(rawValue: "SubSystem3")
        case 129:
            result = ESI.LocationFlag(rawValue: "SubSystem4")
        case 130:
            result = ESI.LocationFlag(rawValue: "SubSystem5")
        case 131:
            result = ESI.LocationFlag(rawValue: "SubSystem6")
        case 132:
            result = ESI.LocationFlag(rawValue: "SubSystem7")
        case 133:
            result = ESI.LocationFlag(rawValue: "SpecializedFuelBay")
        case 134:
            result = ESI.LocationFlag(rawValue: "SpecializedOreHold")
        case 135:
            result = ESI.LocationFlag(rawValue: "SpecializedGasHold")
        case 136:
            result = ESI.LocationFlag(rawValue: "SpecializedMineralHold")
        case 137:
            result = ESI.LocationFlag(rawValue: "SpecializedSalvageHold")
        case 138:
            result = ESI.LocationFlag(rawValue: "SpecializedShipHold")
        case 139:
            result = ESI.LocationFlag(rawValue: "SpecializedSmallShipHold")
        case 140:
            result = ESI.LocationFlag(rawValue: "SpecializedMediumShipHold")
        case 141:
            result = ESI.LocationFlag(rawValue: "SpecializedLargeShipHold")
        case 142:
            result = ESI.LocationFlag(rawValue: "SpecializedIndustrialShipHold")
        case 143:
            result = ESI.LocationFlag(rawValue: "SpecializedAmmoHold")
        case 144:
            result = ESI.LocationFlag(rawValue: "StructureActive")
        case 145:
            result = ESI.LocationFlag(rawValue: "StructureInactive")
        case 146:
            result = ESI.LocationFlag(rawValue: "JunkyardReprocessed")
        case 147:
            result = ESI.LocationFlag(rawValue: "JunkyardTrashed")
        case 148:
            result = ESI.LocationFlag(rawValue: "SpecializedCommandCenterHold")
        case 149:
            result = ESI.LocationFlag(rawValue: "SpecializedPlanetaryCommoditiesHold")
        case 150:
            result = ESI.LocationFlag(rawValue: "PlanetSurface")
        case 151:
            result = ESI.LocationFlag(rawValue: "SpecializedMaterialBay")
        case 152:
            result = ESI.LocationFlag(rawValue: "DustCharacterDatabank")
        case 153:
            result = ESI.LocationFlag(rawValue: "DustCharacterBattle")
        case 154:
            result = ESI.LocationFlag(rawValue: "QuafeBay")
        case 155:
            result = ESI.LocationFlag(rawValue: "FleetHangar")
        case 156:
            result = ESI.LocationFlag(rawValue: "HiddenModifiers")
        case 157:
            result = ESI.LocationFlag(rawValue: "StructureOffline")
        case 158:
            result = ESI.LocationFlag(rawValue: "FighterBay")
        case 159:
            result = ESI.LocationFlag(rawValue: "FighterTube0")
        case 160:
            result = ESI.LocationFlag(rawValue: "FighterTube1")
        case 161:
            result = ESI.LocationFlag(rawValue: "FighterTube2")
        case 162:
            result = ESI.LocationFlag(rawValue: "FighterTube3")
        case 163:
            result = ESI.LocationFlag(rawValue: "FighterTube4")
        case 164:
            result = ESI.LocationFlag(rawValue: "StructureServiceSlot0")
        case 165:
            result = ESI.LocationFlag(rawValue: "StructureServiceSlot1")
        case 166:
            result = ESI.LocationFlag(rawValue: "StructureServiceSlot2")
        case 167:
            result = ESI.LocationFlag(rawValue: "StructureServiceSlot3")
        case 168:
            result = ESI.LocationFlag(rawValue: "StructureServiceSlot4")
        case 169:
            result = ESI.LocationFlag(rawValue: "StructureServiceSlot5")
        case 170:
            result = ESI.LocationFlag(rawValue: "StructureServiceSlot6")
        case 171:
            result = ESI.LocationFlag(rawValue: "StructureServiceSlot7")
        case 172:
            result = ESI.LocationFlag(rawValue: "StructureFuel")
        case 173:
            result = ESI.LocationFlag(rawValue: "Deliveries")
        default:
            result = nil
        }
        if let res = result {
            self = res
        }
        else {
            return nil
        }
    }
    
    var intValue: Int {
        switch self {
        case .wardrobe:
            return 3
        case .hangar:
            return 4
        case .cargo:
            return 5
        case .loSlot0:
            return 11
        case .loSlot1:
            return 12
        case .loSlot2:
            return 13
        case .loSlot3:
            return 14
        case .loSlot4:
            return 15
        case .loSlot5:
            return 16
        case .loSlot6:
            return 17
        case .loSlot7:
            return 18
        case .medSlot0:
            return 19
        case .medSlot1:
            return 20
        case .medSlot2:
            return 21
        case .medSlot3:
            return 22
        case .medSlot4:
            return 23
        case .medSlot5:
            return 24
        case .medSlot6:
            return 25
        case .medSlot7:
            return 26
        case .hiSlot0:
            return 27
        case .hiSlot1:
            return 28
        case .hiSlot2:
            return 29
        case .hiSlot3:
            return 30
        case .hiSlot4:
            return 31
        case .hiSlot5:
            return 32
        case .hiSlot6:
            return 33
        case .hiSlot7:
            return 34
        case .assetSafety:
            return 36
        case .locked:
            return 63
        case .unlocked:
            return 64
        case .droneBay:
            return 87
        case .implant:
            return 89
        case .shipHangar:
            return 90
        case .rigSlot0:
            return 92
        case .rigSlot1:
            return 93
        case .rigSlot2:
            return 94
        case .rigSlot3:
            return 95
        case .rigSlot4:
            return 96
        case .rigSlot5:
            return 97
        case .rigSlot6:
            return 98
        case .rigSlot7:
            return 99
        case .subSystemSlot0:
            return 125
        case .subSystemSlot1:
            return 126
        case .subSystemSlot2:
            return 127
        case .subSystemSlot3:
            return 128
        case .subSystemSlot4:
            return 129
        case .subSystemSlot5:
            return 130
        case .subSystemSlot6:
            return 131
        case .subSystemSlot7:
            return 132
        case .specializedFuelBay:
            return 133
        case .specializedOreHold:
            return 134
        case .specializedGasHold:
            return 135
        case .specializedMineralHold:
            return 136
        case .specializedSalvageHold:
            return 137
        case .specializedShipHold:
            return 138
        case .specializedSmallShipHold:
            return 139
        case .specializedMediumShipHold:
            return 140
        case .specializedLargeShipHold:
            return 141
        case .specializedIndustrialShipHold:
            return 142
        case .specializedAmmoHold:
            return 143
        case .specializedCommandCenterHold:
            return 148
        case .specializedPlanetaryCommoditiesHold:
            return 149
        case .specializedMaterialBay:
            return 151
        case .quafeBay:
            return 154
        case .fleetHangar:
            return 155
        case .hiddenModifiers:
            return 156
        case .fighterBay:
            return 158
        case .fighterTube0:
            return 159
        case .fighterTube1:
            return 160
        case .fighterTube2:
            return 161
        case .fighterTube3:
            return 162
        case .fighterTube4:
            return 163
        case .deliveries:
            return 173
        case .autoFit, .corpseBay, .hangarAll, .subSystemBay, .skill, .boosterBay, .frigateEscapeBay:
            return 0
        }
    }
}

extension ESI.MutableFitting {
    init(_ ship: Ship, managedObjectContext: NSManagedObjectContext) {
        let shipType = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(ship.typeID)).first()
        
        let modules = ship.modules?.map { i -> FlattenCollection<[[ESI.FittingItem]]> in
            let flags: [ESI.FittingItemFlag]
            switch i.key {
            case .hi:
                flags = [.hiSlot0, .hiSlot1, .hiSlot2, .hiSlot3, .hiSlot4, .hiSlot5, .hiSlot6, .hiSlot7]
            case .med:
                flags = [.medSlot0, .medSlot1, .medSlot2, .medSlot3, .medSlot4, .medSlot5, .medSlot6, .medSlot7]
            case .low:
                flags = [.loSlot0, .loSlot1, .loSlot2, .loSlot3, .loSlot4, .loSlot5, .loSlot6, .loSlot7]
            case .rig:
                flags = [.rigSlot0, .rigSlot1, .rigSlot2]
            case .subsystem:
                flags = [.subSystemSlot0, .subSystemSlot1, .subSystemSlot2, .subSystemSlot3]
            case .service:
                flags = [.serviceSlot0, .serviceSlot1, .serviceSlot2, .serviceSlot3, .serviceSlot4, .serviceSlot5, .serviceSlot6, .serviceSlot7]
            default:
                flags = [.cargo]
            }
            var slot = 0
            let items = i.value.map { j -> [ESI.FittingItem] in
                var items: [ESI.FittingItem] = []
                for _ in 0..<j.count {
                    let item = ESI.FittingItem(flag: flags[min(slot, flags.count - 1)], quantity: 1, typeID: j.typeID)
                    slot += 1
                    items.append(item)
                }
                return items
            }.joined()
            return items
        }.joined()
        
        let drones = ship.drones?.compactMap { i -> ESI.FittingItem? in
            guard let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(i.typeID)).first() else {return nil}
            guard let categoryID = type.group?.category?.categoryID, let category = SDECategoryID(rawValue: categoryID) else {return nil}

            let flag = category == .fighter ? ESI.FittingItemFlag.fighterBay : ESI.FittingItemFlag.droneBay
            let item = ESI.FittingItem(flag: flag, quantity: i.count, typeID: i.typeID)
            return item
        }
        let cargo = ship.cargo?.map { i -> ESI.FittingItem in
            ESI.FittingItem(flag: .cargo, quantity: i.count, typeID: i.typeID)
        }
        
        var items: [ESI.FittingItem] = []
        if let modules = modules {
            items.append(contentsOf: modules)
        }
        if let drones = drones {
            items.append(contentsOf: drones)
        }
        if let cargo = cargo {
            items.append(contentsOf: cargo)
        }
        
        self.init(localizedDescription: NSLocalizedString("Created with Neocom on iOS", comment: ""),
                  items: items,
                  name: (ship.name?.isEmpty == false ? ship.name : shipType?.typeName) ?? NSLocalizedString("Unnamed", comment: ""),
                  shipTypeID: ship.typeID)
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
}
