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
	@nonobjc static var currentAccount: NCAccount? {
		didSet {
			NotificationCenter.default.post(name: NSNotification.Name.NCCurrentAccountChanged, object: currentAccount)
		}
	}

	var eveAPIKey: EVEAPIKey {
		get {
			return EVEAPIKey(keyID: Int(self.apiKey!.keyID), vCode: self.apiKey!.vCode!)
		}
	}
	
	var character: EVEAPIKeyInfoCharacter? {
		get {
			return self.apiKey?.apiKeyInfo?.key.characters.first(where: { $0.characterID == Int(self.characterID)})
		}
	}
}
