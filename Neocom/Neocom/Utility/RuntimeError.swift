//
//  RuntimeError.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation

enum RuntimeError: LocalizedError {
    case unknown
    case noAccount
    case noResult
    case invalidOAuth2TOken
    case invalidGang
    case invalidPlanetLayout
    case invalidDNAFormat
    case invalidCharacterURL
    case invalidLoadoutFormat
    case invalidActivityType
    case missingCodingUserInfoKey(CodingUserInfoKey)
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return NSLocalizedString("Unknown error", comment: "")
        case .noAccount:
            return NSLocalizedString("No EVE Account. Please login first.", comment: "")
        case .noResult:
            return NSLocalizedString("No Results", comment: "")
        default:
            return nil
        }
    }
}
