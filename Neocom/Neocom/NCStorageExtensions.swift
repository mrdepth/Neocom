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

	var eveAPIKey: EVEAPIKey {
		get {
			return EVEAPIKey(keyID: Int(self.apiKey!.keyID), vCode: self.apiKey!.vCode!)
		}
	}
}
