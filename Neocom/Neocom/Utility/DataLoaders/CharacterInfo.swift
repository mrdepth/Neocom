//
//  CharacterInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.11.2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import Alamofire

class CharacterInfo: ObservableObject {
	@Published var character: Result<ESI.Characters.CharacterID.Success, AFError>?
	@Published var corporation: Result<ESI.Corporations.CorporationID.Success, AFError>?
	@Published var alliance: Result<ESI.Alliances.AllianceID.Success, AFError>?
	@Published var characterImage: Result<UIImage, AFError>?
	@Published var corporationImage: Result<UIImage, AFError>?
	@Published var allianceImage: Result<UIImage, AFError>?
	
	var characterImageSize: ESI.Image.Size?
	var corporationImageSize: ESI.Image.Size?
	var allianceImageSize: ESI.Image.Size?
	
	init(characterImageSize: ESI.Image.Size?, corporationImageSize: ESI.Image.Size?, allianceImageSize: ESI.Image.Size?) {
		self.characterImageSize = characterImageSize
		self.corporationImageSize = corporationImageSize
		self.allianceImageSize = allianceImageSize
	}
	
	private var subscriptions: [AnyCancellable]?

	func update(esi: ESI, characterID: Int64?) {
        character = nil
        corporation = nil
        alliance = nil
        characterImage = nil
        corporationImage = nil
        allianceImage = nil
		guard let characterID = characterID else {return}
        
		subscriptions = [
			esi.characters.characterID(Int(characterID)).get()
				.asResult()
				.receive(on: DispatchQueue.main)
				.sink { [weak self] result in
					self?.character = result
			},
			
			$character.compactMap{$0}
				.tryGet()
				.flatMap{esi.corporations.corporationID($0.corporationID).get()}
				.asResult()
				.receive(on: DispatchQueue.main)
				.sink { [weak self] result in
					self?.corporation = result
			},
			
			$corporation.compactMap{$0}
				.tryGet()
                .compactMap{$0.allianceID}
				.flatMap{esi.alliances.allianceID($0).get()}
				.asResult()
				.receive(on: DispatchQueue.main)
				.sink { [weak self] result in
					self?.alliance = result
			},
			
			characterImageSize.map {
				esi.image.character(Int(characterID), size: $0)
					.asResult()
					.receive(on: DispatchQueue.main)
					.sink { [weak self] result in
						self?.characterImage = result
				}
			},
			corporationImageSize.map { imageSize in
				$character.compactMap{$0}
					.tryGet()
					.flatMap{esi.image.corporation($0.corporationID, size: imageSize)}
					.asResult()
					.receive(on: DispatchQueue.main)
					.sink { [weak self] result in
						self?.corporationImage = result
				}
			},
			allianceImageSize.map { imageSize in
				$corporation.compactMap{$0}
					.tryGet()
					.compactMap{$0.allianceID}
					.flatMap{esi.image.alliance($0, size: imageSize)}
					.asResult()
					.receive(on: DispatchQueue.main)
					.sink { [weak self] result in
						self?.allianceImage = result
				}
			},
			].compactMap{$0}
	}
}
