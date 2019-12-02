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
    @Published var character: Result<ESI.CharacterInfo, AFError>?
	@Published var corporation: Result<ESI.CorporationInfo, AFError>?
	@Published var alliance: Result<ESI.AllianceInfo, AFError>?
	@Published var characterImage: Result<UIImage, AFError>?
	@Published var corporationImage: Result<UIImage, AFError>?
	@Published var allianceImage: Result<UIImage, AFError>?
	
	init(esi: ESI, characterID: Int64, characterImageSize: ESI.Image.Size? = nil, corporationImageSize: ESI.Image.Size? = nil, allianceImageSize: ESI.Image.Size? = nil) {
        esi.characters.characterID(Int(characterID)).get()
            .asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.character = result
        }.store(in: &subscriptions)
        
        $character.compactMap{$0}
            .tryGet()
            .flatMap{esi.corporations.corporationID($0.corporationID).get()}
            .asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.corporation = result
        }.store(in: &subscriptions)

        $corporation.compactMap{$0}
            .tryGet()
            .compactMap{$0.allianceID}
            .flatMap{esi.alliances.allianceID($0).get()}
            .asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.alliance = result
        }.store(in: &subscriptions)

        characterImageSize.map {
            esi.image.character(Int(characterID), size: $0)
                .asResult()
                .receive(on: RunLoop.main)
                .sink { [weak self] result in
                    self?.characterImage = result
            }
        }?.store(in: &subscriptions)

        corporationImageSize.map { imageSize in
            $character.compactMap{$0}
                .tryGet()
                .flatMap{esi.image.corporation($0.corporationID, size: imageSize)}
                .asResult()
                .receive(on: RunLoop.main)
                .sink { [weak self] result in
                    self?.corporationImage = result
            }
        }?.store(in: &subscriptions)

        allianceImageSize.map { imageSize in
            $corporation.compactMap{$0}
                .tryGet()
                .compactMap{$0.allianceID}
                .flatMap{esi.image.alliance($0, size: imageSize)}
                .asResult()
                .receive(on: RunLoop.main)
                .sink { [weak self] result in
                    self?.allianceImage = result
            }
        }?.store(in: &subscriptions)
    }
	
    private var subscriptions = Set<AnyCancellable>()
}
