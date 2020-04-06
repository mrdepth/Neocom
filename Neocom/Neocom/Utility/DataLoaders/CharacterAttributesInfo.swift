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
    @Published var attributes: Result<ESI.Attributes, AFError>?
    @Published var implants: Result<ESI.Implants, AFError>?

    init(esi: ESI, characterID: Int64) {
        let character = esi.characters.characterID(Int(characterID))
        
        character.attributes().get()
            .asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.attributes = result.map{$0.value}
        }.store(in: &subscriptions)

        character.implants().get()
            .asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.implants = result.map{$0.value}
        }.store(in: &subscriptions)
    }
    
    private var subscriptions = Set<AnyCancellable>()
}
