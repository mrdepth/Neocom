//
//  APIService.swift
//  Neocom
//
//  Created by Artem Shimanski on 15/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import SafariServices
import CloudData

class APIService {
	
	private var didChangeAccountObserver: NotificationObserver?
	
	init() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			guard let strongSelf = self else {return}
			strongSelf.current = strongSelf.make(for: Services.storage.viewContext.currentAccount)
		}
	}
	
	func make(for account: Account?) -> API {
		let esi = ESI(token: account?.oAuth2Token, clientID: Config.current.esi.clientID, secretKey: Config.current.esi.secretKey, server: .tranquility)
		return APIClient(esi: esi)
	}
	
	lazy var current: API = make(for: Services.storage.viewContext.currentAccount)
	
	func performAuthorization(from controller: UIViewController) {
		let url = OAuth2.authURL(clientID: Config.current.esi.clientID, callbackURL: Config.current.esi.callbackURL, scope: ESI.Scope.default, state: "esi")
		controller.present(SFSafariViewController(url: url), animated: true, completion: nil)
	}
}

extension Notification.Name {
	static let didChangeAccount = Notification.Name(rawValue: "didChangeAccount")
}

