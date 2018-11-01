//
//  CharacterInfoInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/1/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class CharacterInfoInteractor: TreeInteractor {
	
	typealias Presenter = CharacterInfoPresenter
	typealias Content = ESI.Result<Value>
	weak var presenter: Presenter?
	
	struct Value {
		let character: ESI.Character.Information?
		let clones: ESI.Clones.JumpClones?
		let attributes: ESI.Skills.CharacterAttributes?
		let implants: [Int]?
		let skills: ESI.Skills.CharacterSkills?
		let skillQueue: [ESI.Skills.SkillQueueItem]?
		let walletBalance: Double?
		let characterImage: UIImage?
		let location: ESI.Location.CharacterLocation?
		let ship: ESI.Location.CharacterShip?
		let corporation: ESI.Corporation.Information?
		let corporationImage: UIImage?
		let alliance: ESI.Alliance.Information?
		let allianceImage: UIImage?
	}
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	private var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		guard let characterID = Services.storage.viewContext.currentAccount?.characterID else { return .init(.failure(NCError.authenticationRequired)) }
		
		let api = self.api
		let progress = Progress(totalUnitCount: 14)
		return DispatchQueue.global(qos: .utility).async { () -> Content in
			let (character, clones, attributes, implants, skills, skillQueue) = try any(
				progress.performAsCurrent(withPendingUnitCount: 1) {api.characterInformation(cachePolicy: cachePolicy)},
				progress.performAsCurrent(withPendingUnitCount: 1) {api.clones(cachePolicy: cachePolicy)},
				progress.performAsCurrent(withPendingUnitCount: 1) {api.characterAttributes(cachePolicy: cachePolicy)},
				progress.performAsCurrent(withPendingUnitCount: 1) {api.implants(cachePolicy: cachePolicy)},
				progress.performAsCurrent(withPendingUnitCount: 1) {api.skills(cachePolicy: cachePolicy)},
				progress.performAsCurrent(withPendingUnitCount: 1) {api.skillQueue(cachePolicy: cachePolicy)}
				).get()
			
			let (walletBalance, characterImage, location, ship) = try any(
				progress.performAsCurrent(withPendingUnitCount: 1) {api.walletBalance(cachePolicy: cachePolicy)},
				progress.performAsCurrent(withPendingUnitCount: 1) {api.image(characterID: characterID, dimension: 512, cachePolicy: cachePolicy)},
				progress.performAsCurrent(withPendingUnitCount: 1) {api.characterLocation(cachePolicy: cachePolicy)},
				progress.performAsCurrent(withPendingUnitCount: 1) {api.characterShip(cachePolicy: cachePolicy)}
			).get()
			
			let corporation = (try? progress.performAsCurrent(withPendingUnitCount: 1) {
				(character?.value.corporationID).map{api.corporationInformation(corporationID: Int64($0), cachePolicy: cachePolicy)}
			}?.get()) ?? nil
			
			let corporationImage = (try? progress.performAsCurrent(withPendingUnitCount: 1) {
				(character?.value.corporationID).map{api.image(corporationID: Int64($0), dimension: 32, cachePolicy: cachePolicy)}
				}?.get()) ?? nil
			
			let alliance = (try? progress.performAsCurrent(withPendingUnitCount: 1) {
				(corporation?.value.allianceID).map{api.allianceInformation(allianceID: Int64($0), cachePolicy: cachePolicy)}
				}?.get()) ?? nil

			let allianceImage = (try? progress.performAsCurrent(withPendingUnitCount: 1) {
				(character?.value.allianceID).map{api.image(allianceID: Int64($0), dimension: 32, cachePolicy: cachePolicy)}
				}?.get()) ?? nil

			let value = Value(character: character?.value,
							  clones: clones?.value,
							  attributes: attributes?.value,
							  implants: implants?.value,
							  skills: skills?.value,
							  skillQueue: skillQueue?.value,
							  walletBalance: walletBalance?.value,
							  characterImage: characterImage?.value,
							  location: location?.value,
							  ship: ship?.value,
							  corporation: corporation?.value,
							  corporationImage: corporationImage?.value,
							  alliance: alliance?.value,
							  allianceImage: allianceImage?.value)
			
			let expires = [character?.expires,
						   clones?.expires,
						   attributes?.expires,
						   implants?.expires,
						   skills?.expires,
						   skillQueue?.expires,
						   walletBalance?.expires,
						   characterImage?.expires,
						   location?.expires,
						   ship?.expires,
						   corporation?.expires,
						   corporationImage?.expires,
						   alliance?.expires,
						   allianceImage?.expires].compactMap ({$0}).min()
			
			return Content(value: value, expires: expires)
		}
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			self?.api = Services.api.current
			_ = self?.presenter?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter?.view?.present(presentation, animated: true)
			}
		}
	}
}
