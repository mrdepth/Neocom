//
//  Settings.swift
//  Neocom
//
//  Created by Artem Shimanski on 13/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class Settings {
	
	private enum Key {
		static let currentAccount = "com.shimanski.neocom.currentAccount"
		static let marketRegionID = "com.shimanski.neocom.marketRegionID"
		static let firstLaunchDate = "com.shimanski.neocom.firstLaunchDate"
		static let lastReviewDate = "com.shimanski.neocom.lastReviewDate"
		static let consent = "com.shimanski.neocom.consent"
	}
	
	var currentAccount: URL? {
		get { return Services.userDefaults.url(forKey: Key.currentAccount) }
		set { Services.userDefaults.set(newValue, forKey: Key.currentAccount) }
	}
	
	var marketRegionID: Int {
		get { return Services.userDefaults.object(forKey: Key.marketRegionID) as? Int ?? SDERegionID.theForge.rawValue }
		set { Services.userDefaults.set(newValue, forKey: Key.marketRegionID) }
	}
	
	var firstLaunchDate: Date? {
		get { return Services.userDefaults.object(forKey: Key.firstLaunchDate) as? Date }
		set { Services.userDefaults.set(newValue, forKey: Key.firstLaunchDate) }
	}

	var lastReviewDate: Date? {
		get { return Services.userDefaults.object(forKey: Key.lastReviewDate) as? Date }
		set { Services.userDefaults.set(newValue, forKey: Key.lastReviewDate) }
	}

	var consent: Bool? {
		get { return Services.userDefaults.object(forKey: Key.consent) as? Bool }
		set { Services.userDefaults.set(newValue, forKey: Key.consent) }
	}
}
