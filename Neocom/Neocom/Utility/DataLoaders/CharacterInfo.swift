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
    @Published var isLoading = false
    @Published var character: Result<ESI.CharacterInfo, AFError>?
	@Published var corporation: Result<ESI.CorporationInfo, AFError>?
	@Published var alliance: Result<ESI.AllianceInfo, AFError>?
	@Published var characterImage: Result<UIImage, AFError>?
	@Published var corporationImage: Result<UIImage, AFError>?
	@Published var allianceImage: Result<UIImage, AFError>?
    
    private var esi: ESI
    private var characterID: Int64
    private var characterImageSize: ESI.Image.Size?
    private var corporationImageSize: ESI.Image.Size?
    private var allianceImageSize: ESI.Image.Size?
	
	init(esi: ESI, characterID: Int64, characterImageSize: ESI.Image.Size? = nil, corporationImageSize: ESI.Image.Size? = nil, allianceImageSize: ESI.Image.Size? = nil) {
        self.esi = esi
        self.characterID = characterID
        self.characterImageSize = characterImageSize
        self.corporationImageSize = corporationImageSize
        self.allianceImageSize = allianceImageSize
        update(cachePolicy: .useProtocolCachePolicy)
    }
    
    func update(cachePolicy: URLRequest.CachePolicy) {
        let esi = self.esi
        subscriptions.removeAll()
        isLoading = true
        
        let character = esi.characters.characterID(Int(characterID)).get(cachePolicy: cachePolicy)
            .map{$0.value}
            .receive(on: RunLoop.main)
            .share()
            
        character.asResult().sink { [weak self] result in
            self?.character = result
        }.store(in: &subscriptions)
        
        let corporation = character.flatMap{esi.corporations.corporationID($0.corporationID).get(cachePolicy: cachePolicy)}
            .map{$0.value}
            .receive(on: RunLoop.main)
            .share()
        
        corporation.asResult().sink { [weak self] result in
            self?.corporation = result
        }.store(in: &subscriptions)

        let alliance = corporation.compactMap{$0.allianceID}
            .flatMap{esi.alliances.allianceID($0).get(cachePolicy: cachePolicy)}
            .map{$0.value}
            .receive(on: RunLoop.main)
            
        alliance.asResult().sink { [weak self] result in
            self?.alliance = result
        }.store(in: &subscriptions)
        
        character.zip(corporation).sink(receiveCompletion: {[weak self] _ in
            self?.isLoading = false
            }, receiveValue: {_ in})
            .store(in: &subscriptions)

        characterImageSize.map {
            esi.image.character(Int(characterID), size: $0, cachePolicy: cachePolicy)
                .asResult()
                .receive(on: RunLoop.main)
                .sink { [weak self] result in
                    self?.characterImage = result
            }
        }?.store(in: &subscriptions)

        corporationImageSize.map { imageSize in
            character.flatMap{esi.image.corporation($0.corporationID, size: imageSize, cachePolicy: cachePolicy)}
                .asResult()
                .receive(on: RunLoop.main)
                .sink { [weak self] result in
                    self?.corporationImage = result
            }
        }?.store(in: &subscriptions)

        allianceImageSize.map { imageSize in
            corporation.compactMap{$0.allianceID}
                .flatMap{esi.image.alliance($0, size: imageSize, cachePolicy: cachePolicy)}
                .asResult()
                .receive(on: RunLoop.main)
                .sink { [weak self] result in
                    self?.allianceImage = result
            }
        }?.store(in: &subscriptions)
    }
	
    private var subscriptions = Set<AnyCancellable>()
}
