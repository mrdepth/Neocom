//
//  SkillLevelsLoader.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/23/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Dgmpp
import Combine
import CoreData
import EVEAPI

enum DGMSkillLevels {
    case levelsMap([DGMTypeID: Int], URL?)
    case level(Int)
    
    static func fromAccount(_ account: Account, managedObjectContext: NSManagedObjectContext) -> AnyPublisher<DGMSkillLevels, Error> {
        guard let token = account.oAuth2Token else {return Fail(error: RuntimeError.invalidOAuth2TOken).eraseToAnyPublisher()}
        let esi = ESI(token: token)
        return Pilot.load(esi.characters.characterID(Int(account.characterID)), in: managedObjectContext).map { pilot in
            .levelsMap(pilot.trainedSkills.mapValues{$0.trainedSkillLevel}, DGMCharacter.url(account: account))
        }
        .mapError{$0 as Error}
        .eraseToAnyPublisher()
    }
    
    static func load(_ account: Account?, managedObjectContext: NSManagedObjectContext) -> AnyPublisher<DGMSkillLevels, Never> {
        Just(account)
            .compactMap{$0}
            .flatMap {DGMSkillLevels.fromAccount($0, managedObjectContext: managedObjectContext).replaceError(with: .level(5))}
            .replaceEmpty(with: .level(5))
            .eraseToAnyPublisher()
    }
}

class SkillLevelsLoader: ObservableObject {
    @Published var skillLevels: DGMSkillLevels = .level(5)
    
    private var subscripton: AnyCancellable?
    
    init(_ account: Account?, managedObjectContext: NSManagedObjectContext) {
        subscripton = Just(account)
            .compactMap{$0}
            .flatMap {DGMSkillLevels.fromAccount($0, managedObjectContext: managedObjectContext).replaceError(with: .level(5))}
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.skillLevels = $0
        }
    }
}
