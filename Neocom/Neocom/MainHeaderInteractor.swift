//
//  MainHeaderInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

class MainHeaderInteractor: ContentProviderInteractor {
	weak var presenter: MainHeaderPresenter!
	lazy var cache: Cache! = CacheContainer.shared
	lazy var sde: SDE! = SDEContainer.shared
	lazy var storage: Storage! = StorageContainer.shared

	required init(presenter: MainHeaderPresenter) {
		self.presenter = presenter
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Void> {
		guard let account = storage.viewContext.currentAccount else {return .init(.failure(NCError.authenticationRequired))}
		let progress = Progress(totalUnitCount: 4)
		let api = self.api(cachePolicy: cachePolicy)

		DispatchQueue.global(qos: .utility).async {
			let characterInfo = try api.characterInformation().get()
			let characterImage = try? api.image(characterID: account.characterID, dimension: 128).get()
			let corporationImage = try? api.image(corporationID: characterInfo.value.corporationID, dimension: 32)
			if let allianceID {
				
			}
		}
	}
	
}
