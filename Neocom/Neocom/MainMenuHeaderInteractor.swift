//
//  MainMenuHeaderInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import EVEAPI

class MainMenuHeaderInteractor: ContentProviderInteractor {
	weak var presenter: MainMenuHeaderPresenter!
	
	typealias Content = ESI.Result<Info>
	
	struct Info {
		var characterName: String?
		var characterImage: UIImage?
		var corporation: String?
		var corporationImage: UIImage?
		var alliance: String?
		var allianceImage: UIImage?
	}

	required init(presenter: MainMenuHeaderPresenter) {
		self.presenter = presenter
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<ESI.Result<Info>> {
		guard let account = Services.storage.viewContext.currentAccount else {return .init(.failure(NCError.authenticationRequired))}
		let progress = Progress(totalUnitCount: 6)
		let api = Services.api.current
		
		let metrics = presenter.view.metrics
		let characterID = account.characterID

		return DispatchQueue.global(qos: .utility).async { () -> ESI.Result<Info> in
			let characterInfo =  try progress.performAsCurrent(withPendingUnitCount: 1) { try api.characterInformation(cachePolicy: cachePolicy).get() }
			let characterImage = progress.performAsCurrent(withPendingUnitCount: 1) { try? api.image(characterID: characterID, dimension: metrics.characterImageDimension, cachePolicy: cachePolicy).get() }
			let corporationInfo = progress.performAsCurrent(withPendingUnitCount: 1) { try? api.corporationInformation(corporationID: Int64(characterInfo.value.corporationID), cachePolicy: cachePolicy).get() }
			let corporationImage = progress.performAsCurrent(withPendingUnitCount: 1) { try? api.image(corporationID: Int64(characterInfo.value.corporationID), dimension: metrics.corporationImageDimension, cachePolicy: cachePolicy).get() }
			
			let allianceInformation: ESI.Result<ESI.Alliance.Information>?
			let allianceImage: ESI.Result<UIImage>?
			
			if let allianceID = characterInfo.value.allianceID {
				allianceInformation = progress.performAsCurrent(withPendingUnitCount: 1) { try? api.allianceInformation(allianceID: Int64(allianceID), cachePolicy: cachePolicy).get() }
				allianceImage = progress.performAsCurrent(withPendingUnitCount: 1) { try? api.image(allianceID: Int64(allianceID), dimension: metrics.allianceImageDimension, cachePolicy: cachePolicy).get() }
			}
			else {
				allianceInformation = nil
				allianceImage = nil
			}
			
			let value = Info(characterName: characterInfo.value.name,
							 characterImage: characterImage?.value,
							 corporation: corporationInfo?.value.name,
							 corporationImage: corporationImage?.value,
							 alliance: allianceInformation?.value.name,
							 allianceImage: allianceImage?.value)
			let expires = [characterInfo.expires, characterImage?.expires, corporationInfo?.expires, corporationImage?.expires, allianceInformation?.expires, allianceImage?.expires].compactMap {$0}.min()
			return ESI.Result(value: value, expires: expires)
		}
	}
	
}
