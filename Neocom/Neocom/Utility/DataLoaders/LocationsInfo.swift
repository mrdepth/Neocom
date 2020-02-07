//
//  LocationsInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/11/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import CoreData
import Expressible
import Alamofire

//class LocationsInfo: ObservableObject {
//
//    init(locationIDs: [Int64], esi: ESI, managedObjectContext: NSManagedObjectContext) {
//    }
//}

struct EVELocation: Hashable {
    struct SolarSystem: Hashable {
        let solarSystemID: Int
        let solarSystemName: String
        let security: Float
        
        init(_ solarSystem: SDEMapSolarSystem) {
            solarSystemID = Int(solarSystem.solarSystemID)
            solarSystemName = solarSystem.solarSystemName ?? NSLocalizedString("Unknown", comment: "")
            security = solarSystem.security
        }
    }
    
    static func unknown(_ id: Int64) -> EVELocation {
        EVELocation(solarSystem: nil, structureName: nil, id: id)
    }
    
    let structureName: String?
    let solarSystem: SolarSystem?
    let name: String
    let id: Int64
    
    func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
    
    init(_ station: SDEStaStation) {
        self.init(solarSystem: station.solarSystem, structureName: station.stationName, id: Int64(station.stationID))
    }
    
    init(_ name: ESI.ItemName, managedObjectContext: NSManagedObjectContext) {
        if name.category == .solarSystem {
            let solarSystem = try? managedObjectContext.from(SDEMapSolarSystem.self).filter(\SDEMapSolarSystem.solarSystemID == name.id).first()
            self.init(solarSystem: solarSystem, structureName: name.name, id: Int64(name.id))
        }
        else {
            self.init(solarSystem: nil, structureName: name.name, id: Int64(name.id))
        }
    }
    
    init(_ structure: ESI.StructureInfo, id: Int64, managedObjectContext: NSManagedObjectContext) {
        let solarSystem = try? managedObjectContext.from(SDEMapSolarSystem.self).filter(\SDEMapSolarSystem.solarSystemID == structure.solarSystemID).first()
        self.init(solarSystem: solarSystem, structureName: structure.name, id: id)
    }
    
    init(solarSystem: SDEMapSolarSystem?, structureName: String? = nil, id: Int64) {
        self.structureName = structureName
        self.solarSystem = solarSystem.map{SolarSystem($0)}
        
        let solarSystemName: String
        let locationName: String
        if let solarSystem = self.solarSystem {
            if let name = structureName {
                if name.hasPrefix(solarSystem.solarSystemName) {
                    solarSystemName = solarSystem.solarSystemName
                    locationName = String(name.dropFirst(solarSystemName.count))
                }
                else {
                    solarSystemName = ""
                    locationName = name
                }
            }
            else {
                solarSystemName = solarSystem.solarSystemName
                locationName = ""
            }
        }
        else {
            solarSystemName = ""
            locationName = structureName ?? NSLocalizedString("\u{2063}Unknown Location", comment: "")
        }
        name = solarSystemName + " " + locationName
        self.id = id
    }
    
    static var cache = Atomic<[Int64: EVELocation]>([:])
    
    static func locations(with ids: Set<Int64>, esi: ESI, managedObjectContext: NSManagedObjectContext) -> AnyPublisher<[Int64: EVELocation], Never> {
        return Just(ids).receive(on: managedObjectContext).flatMap { ids -> AnyPublisher<[Int64: EVELocation], Never> in
            let structureIDs = ids.filter{$0 > Int64(Int32.max)}
            var missingIDs = ids.subtracting(structureIDs)
            let cached = cache.wrappedValue.filter{ids.contains($0.key)}
            missingIDs.subtract(cached.keys)
            let stations = (try? managedObjectContext.from(SDEStaStation.self).filter((\SDEStaStation.stationID).in(missingIDs)).fetch().map {(Int64($0.stationID), EVELocation($0))}) ?? []
            missingIDs.subtract(stations.map{$0.0})
            
            var publishers = structureIDs.map { id in
                esi.universe.structures().structureID(id).get().flatMap { structure in
                    Future<[(Int64, EVELocation)], AFError> { promise in
                        managedObjectContext.perform {
                            let locations = [(id, EVELocation(structure.value, id: id, managedObjectContext: managedObjectContext))]
                            cache.wrappedValue.merge(locations, uniquingKeysWith: {a, _ in a})
                            promise(.success(locations))
                        }
                    }
                }.replaceError(with: []).eraseToAnyPublisher()
            }
            if !missingIDs.isEmpty {
                let p = esi.universe.names().post(ids: missingIDs.map{Int($0)}).flatMap { names in
                    Future<[(Int64, EVELocation)], AFError> { promise in
                        managedObjectContext.perform {
                            let locations = names.value.map{(Int64($0.id), EVELocation($0, managedObjectContext: managedObjectContext))}
                            cache.wrappedValue.merge(locations, uniquingKeysWith: {a, _ in a})
                            promise(.success(locations))
                        }
                    }
                }
                .replaceError(with: [])
                .eraseToAnyPublisher()
                publishers.append(p)
            }
            return Publishers.MergeMany(publishers).collect().map {
                Dictionary(($0 + [stations]).joined()) { (a, _) in a }
            }.eraseToAnyPublisher()
		}.eraseToAnyPublisher()
    }
}
