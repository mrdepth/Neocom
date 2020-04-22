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
    @Published var isLoading = false
    @Published var result: Result<DGMPlanet, Error>?
    
    private var subscription: AnyCancellable?
    private var esi: ESI
    private var characterID: Int64
    private var planet: ESI.Planets.Element
    
    init(esi: ESI, characterID: Int64, planet: ESI.Planets.Element) {
        self.esi = esi
        self.characterID = characterID
        self.planet = planet
        update(cachePolicy: .useProtocolCachePolicy)
    }
    
    func update(cachePolicy: URLRequest.CachePolicy) {
        isLoading = true
        let planet = self.planet
        
        subscription = esi.characters.characterID(Int(characterID)).planets().planetID(planet.planetID).get(cachePolicy: cachePolicy).receive(on: DispatchQueue.global(qos: .utility))
            .map{$0.value}
            .tryMap { info -> DGMPlanet in
                let planet = try DGMPlanet(planet: planet, info: info)
                planet.run()
                return planet
        }
        .receive(on: RunLoop.main)
        .asResult()
        .sink { [weak self] in
            self?.result = $0
            self?.isLoading = false
        }
    }
}
