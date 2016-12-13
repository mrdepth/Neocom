//
//  NCStorageExtensions.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

extension NCAccount {
	@nonobjc static var currentAccount: NCAccount?

	var token: OAuth2Token {
		get {
			let token = OAuth2Token(accessToken: accessToken!, refreshToken: refreshToken!, tokenType: tokenType!, characterID: characterID, characterName: characterName!, realm: realm!)
			token.expiresOn = expiresOn! as Date
			return token
		}
		set {
			let token = newValue
			if accessToken != token.accessToken {accessToken = token.accessToken}
			if refreshToken != token.refreshToken {refreshToken = token.refreshToken}
			if tokenType != token.tokenType {tokenType = token.tokenType}
			if characterID != token.characterID {characterID = token.characterID}
			if characterName != token.characterName {characterName = token.characterName}
			if realm != token.realm {realm = token.realm}
			if let expiresOn = token.expiresOn as NSDate?, expiresOn != self.expiresOn {
				self.expiresOn = expiresOn
			}
		}
	}
	
}
