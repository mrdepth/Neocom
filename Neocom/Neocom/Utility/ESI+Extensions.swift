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
    
    convenience init(token: OAuth2Token) {
        self.init(token: token, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey)
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
