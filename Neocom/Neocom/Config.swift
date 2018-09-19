//
//  Config.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

struct Config: Hashable {
	struct ESI: Hashable {
		var clientID = "a0cc80b7006944249313dc22205ec645"
		var secretKey = "deUqMep7TONp68beUoC1c71oabAdKQOJdbiKpPcC"
		var callbackURL = URL(string: "eveauthnc://sso/")!
	}
	var esi = ESI()
	
	var maxCacheTime: TimeInterval = 3600 * 48
}


extension Config {
	static let current = Config()
}

extension UserDefaults {
	struct Key {
		static let currentAccount = "com.shimanski.neocom.currentAccount"
		static let marketRegion = "com.shimanski.neocom.marketRegion"
		static let firstLaunchDate = "com.shimanski.neocom.firstLaunchDate"
		static let lastReviewDate = "com.shimanski.neocom.lastReviewDate"
		static let consent = "com.shimanski.neocom.consent"
	}
}
