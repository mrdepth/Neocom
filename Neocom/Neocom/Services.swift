//
//  Services.swift
//  Neocom
//
//  Created by Artem Shimanski on 31.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

protocol APIService {
	func make(for account: Account?) -> API
	var current: API {get}
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
		let esi = ESI(token: nil, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey, server: .tranquility)
		return APIClient(esi: esi)
	}
}
