//
//  Services.swift
//  Neocom
//
//  Created by Artem Shimanski on 31.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import SafariServices

protocol APIService {
	func make(for account: Account?) -> API
	var current: API {get}
	
	func performAuthorization(from controller: UIViewController)
}

struct Services {
	static var cache: Cache = CacheContainer()
	static var storage: Storage = StorageContainer()
	static var sde: SDE = SDEContainer()
	static var api: APIService = DefaultAPIService()
}

class DefaultAPIService: APIService {
	
	func make(for account: Account?) -> API {
		let esi = ESI(token: account?.oAuth2Token, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey, server: .tranquility)
		return APIClient(esi: esi)
	}
	
	var current: API {
		return make(for: Services.storage.viewContext.currentAccount)
	}
	
	func performAuthorization(from controller: UIViewController) {
		let url = OAuth2.authURL(clientID: Config.current.esi.clientID, callbackURL: Config.current.esi.callbackURL, scope: ESI.Scope.default, state: "esi")
		controller.present(SFSafariViewController(url: url), animated: true, completion: nil)
	}
}

extension Notification.Name {
	static let didChangeAccount = Notification.Name(rawValue: "didChangeAccount")
}

