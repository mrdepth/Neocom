//
//  CharacterAttributesInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/20/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Alamofire
import Expressible
import Combine
import CoreData

class CharacterAttributesInfo: ObservableObject {
    @Published var isLoading = false
    @Published var attributes: Result<ESI.Attributes, AFError>?
    @Published var implants: Result<ESI.Implants, AFError>?

    private var esi: ESI
    private var characterID: Int64

    init(esi: ESI, characterID: Int64) {
        self.esi = esi
        self.characterID = characterID

        update(cachePolicy: .useProtocolCachePolicy)
    }
    
    func update(cachePolicy: URLRequest.CachePolicy) {
        let esi = self.esi
        subscriptions.removeAll()
        isLoading = true

        let character = esi.characters.characterID(Int(characterID))
        
        let attributes = character.attributes().get()
            .map{$0.value}
            .receive(on: RunLoop.main)
            .share()

        attributes.asResult().sink { [weak self] result in
            self?.attributes = result
        }.store(in: &subscriptions)

        let implants = character.implants().get()
            .map{$0.value}
            .receive(on: RunLoop.main)
            .share()
        
        implants.asResult().sink { [weak self] result in
            self?.implants = result
        }.store(in: &subscriptions)
        
        attributes.zip(implants).sink(receiveCompletion: {[weak self] _ in
            self?.isLoading = false
            }, receiveValue: {_ in})
            .store(in: &subscriptions)

    }
    
    private var subscriptions = Set<AnyCancellable>()
}
