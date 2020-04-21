//
//  AccountInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/29/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Alamofire
import Expressible
import Combine
import CoreData

class AccountInfo: ObservableObject {
    @Published var isLoading = false
    @Published var skillQueue: Result<[ESI.SkillQueueItem], AFError>?
    @Published var ship: Result<ESI.Ship, AFError>?
    @Published var location: Result<SDEMapSolarSystem, AFError>?
    @Published var skills: Result<ESI.CharacterSkills, AFError>?
    @Published var balance: Result<Double, AFError>?
    
    private var esi: ESI
    private var characterID: Int64
    private var managedObjectContext: NSManagedObjectContext

    init(esi: ESI, characterID: Int64, managedObjectContext: NSManagedObjectContext) {
        self.esi = esi
        self.characterID = characterID
        self.managedObjectContext = managedObjectContext
        update(cachePolicy: .useProtocolCachePolicy)
    }
    
    func update(cachePolicy: URLRequest.CachePolicy) {
        let esi = self.esi
        let managedObjectContext = self.managedObjectContext
        subscriptions.removeAll()
        isLoading = true

        let character = esi.characters.characterID(Int(characterID))
        
        let ship = character.ship().get()
            .map{$0.value}
            .receive(on: RunLoop.main)
            .share()

        ship.asResult().sink { [weak self] result in
            self?.ship = result
        }.store(in: &subscriptions)

        let skills = character.skills().get()
            .map{$0.value}
            .receive(on: RunLoop.main)
            .share()
        
        skills.asResult().sink { [weak self] result in
            self?.skills = result
        }.store(in: &subscriptions)
        
        let wallet = character.wallet().get()
            .map{$0.value}
            .receive(on: RunLoop.main)
            .share()
            
        wallet.asResult().sink { [weak self] result in
            self?.balance = result
        }.store(in: &subscriptions)
        
        let location = character.location().get()
            .map{$0.value}
            .receive(on: RunLoop.main)
            .share()
        
        location.compactMap { location in
            try? managedObjectContext.from(SDEMapSolarSystem.self).filter(/\SDEMapSolarSystem.solarSystemID == Int32(location.solarSystemID)).first()
        }
        .asResult()
        .sink { [weak self] result in
            self?.location = result
        }.store(in: &subscriptions)
        
        let skillQueue = character.skillqueue().get()
            .map{$0.value}
            .receive(on: RunLoop.main)
            .share()

        skillQueue.map{$0.filter{$0.finishDate.map{$0 > Date()} == true}}
            .asResult()
            .sink { [weak self] result in
                self?.skillQueue = result
        }.store(in: &subscriptions)
        
        ship.zip(skills).zip(wallet).zip(location).zip(skillQueue).sink(receiveCompletion: {[weak self] _ in
            self?.isLoading = false
            }, receiveValue: {_ in})
            .store(in: &subscriptions)
    }
    
    private var subscriptions = Set<AnyCancellable>()
}
