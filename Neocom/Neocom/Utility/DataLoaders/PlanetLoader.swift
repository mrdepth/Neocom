//
//  PlanetLoader.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/1/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Combine
import Dgmpp
import Alamofire

class PlanetLoader: ObservableObject {
    @Published var result: Result<DGMPlanet, Error>?
    
    private var subscription: AnyCancellable?
    
    init(esi: ESI, characterID: Int64, planet: ESI.Planets.Element) {
        subscription = esi.characters.characterID(Int(characterID)).planets().planetID(planet.planetID).get().receive(on: DispatchQueue.global(qos: .utility))
            .map{$0.value}
            .tryMap {
                let planet = try DGMPlanet(planet: planet, info: $0)
                planet.run()
                return planet
        }
        .receive(on: RunLoop.main)
        .asResult()
        .sink { [weak self] in
            self?.result = $0
        }
    }
}
