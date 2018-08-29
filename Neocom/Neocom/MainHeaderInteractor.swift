//
//  MainHeaderInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import EVEAPI

class MainHeaderInteractor: ContentProviderInteractor {
	weak var presenter: MainHeaderPresenter!
	lazy var cache: Cache! = CacheContainer.shared
	lazy var sde: SDE! = SDEContainer.shared
	lazy var storage: Storage! = StorageContainer.shared
	
	typealias Content = CachedValue<Info>
	
	struct Info {
		var characterName: String?
		var characterImage: UIImage?
		var corporation: String?
		var corporationImage: UIImage?
		var alliance: String?
		var allianceImage: UIImage?
	}

	required init(presenter: MainHeaderPresenter) {
		self.presenter = presenter
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<CachedValue<Info>> {
		guard let account = storage.viewContext.currentAccount else {return .init(.failure(NCError.authenticationRequired))}
		let progress = Progress(totalUnitCount: 6)
		let api = self.api(cachePolicy: cachePolicy)

		return DispatchQueue.global(qos: .utility).async { () -> CachedValue<Info> in
			let characterInfo =  try progress.performAsCurrent(withPendingUnitCount: 1) { try api.characterInformation().get() }
			let characterImage = progress.performAsCurrent(withPendingUnitCount: 1) { try? api.image(characterID: account.characterID, dimension: 128).get() }
			let corporationInfo = progress.performAsCurrent(withPendingUnitCount: 1) { try? api.corporationInformation(corporationID: Int64(characterInfo.value.corporationID)).get() }
			let corporationImage = progress.performAsCurrent(withPendingUnitCount: 1) { try? api.image(corporationID: Int64(characterInfo.value.corporationID), dimension: 32).get() }
			
			let allianceInformation: CachedValue<ESI.Alliance.Information>?
			let allianceImage: CachedValue<UIImage>?
			
			if let allianceID = characterInfo.value.allianceID {
				allianceInformation = progress.performAsCurrent(withPendingUnitCount: 1) { try? api.allianceInformation(allianceID: Int64(allianceID)).get() }
				allianceImage = progress.performAsCurrent(withPendingUnitCount: 1) { try? api.image(allianceID: Int64(allianceID), dimension: 32).get() }
			}
			else {
				allianceInformation = nil
				allianceImage = nil
			}
			
			return all(characterInfo, characterImage, corporationInfo, corporationImage, allianceInformation, allianceImage).map { Info(characterName: $0?.name, characterImage: $1, corporation: $2?.name, corporationImage: $3, alliance: $4?.name, allianceImage: $5) }
		}
		
	}
	
}
