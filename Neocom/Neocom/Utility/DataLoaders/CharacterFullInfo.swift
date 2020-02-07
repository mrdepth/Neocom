//
//  CharacterFullInfo.swift
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

class CharacterFullInfo: AccountInfo {
    @Published var attributes: Result<ESI.Attributes, AFError>?
    @Published var implants: Result<ESI.Implants, AFError>?

    override init(esi: ESI, characterID: Int64, managedObjectContext: NSManagedObjectContext, characterImageSize: ESI.Image.Size? = nil, corporationImageSize: ESI.Image.Size? = nil, allianceImageSize: ESI.Image.Size? = nil) {
        super.init(esi: esi, characterID: characterID, managedObjectContext: managedObjectContext, characterImageSize: characterImageSize, corporationImageSize: corporationImageSize, allianceImageSize: allianceImageSize)
        
        let character = esi.characters.characterID(Int(characterID))
        
        character.attributes().get()
            .asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.attributes = result.map{$0.value}
                self?.objectWillChange.send()
        }.store(in: &subscriptions)

        character.implants().get()
            .asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.implants = result.map{$0.value}
                self?.objectWillChange.send()
        }.store(in: &subscriptions)
    }
}
