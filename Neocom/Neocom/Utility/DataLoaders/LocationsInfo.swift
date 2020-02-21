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
            let solarSystem = try? managedObjectContext.from(SDEMapSolarSystem.self).filter(/\SDEMapSolarSystem.solarSystemID == Int32(name.id)).first()
            self.init(solarSystem: solarSystem, structureName: name.name, id: Int64(name.id))
        }
        else {
            self.init(solarSystem: nil, structureName: name.name, id: Int64(name.id))
        }
    }
    
    init(_ structure: ESI.StructureInfo, id: Int64, managedObjectContext: NSManagedObjectContext) {
        let solarSystem = try? managedObjectContext.from(SDEMapSolarSystem.self).filter(/\SDEMapSolarSystem.solarSystemID == Int32(structure.solarSystemID)).first()
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
    
    static func locations(with ids: Set<Int64>, esi: ESI, managedObjectContext: NSManagedObjectContext, progress: Alamofire.Request.ProgressHandler? = nil) -> AnyPublisher<[Int64: EVELocation], Never> {
        return Just(ids).receive(on: managedObjectContext).flatMap { ids -> AnyPublisher<[Int64: EVELocation], Never> in
            let cached = cache.wrappedValue.filter{ids.contains($0.key)}
            var structureIDs = ids.filter{$0 > Int64(Int32.max)}
            var missingIDs = ids.subtracting(structureIDs)

            missingIDs.subtract(cached.keys)
            structureIDs.subtract(cached.keys)
            let stationIDs = missingIDs.compactMap{Int32(exactly: $0)}
            let stations = stationIDs.isEmpty ? [] : (try? managedObjectContext.from(SDEStaStation.self).filter((/\SDEStaStation.stationID).in(stationIDs)).fetch().map {(Int64($0.stationID), EVELocation($0))}) ?? []
            missingIDs.subtract(stations.map{$0.0})
            
            let totalProgress = Progress(totalUnitCount: Int64(structureIDs.count) + 1)
            
            let names: AnyPublisher<[(Int64, EVELocation)], Never>
            
            names = totalProgress.performAsCurrent(withPendingUnitCount: 1, totalUnitCount: 100) { p in
                if !missingIDs.isEmpty {
                    return esi.universe.names().post(ids: missingIDs.map{Int($0)}) {
                        p.completedUnitCount = Int64($0.fractionCompleted * 100)
                        progress?(totalProgress)
                    }.flatMap { names in
                        Future<[(Int64, EVELocation)], AFError> { promise in
                            managedObjectContext.perform {
                                let locations = names.value.map{(Int64($0.id), EVELocation($0, managedObjectContext: managedObjectContext))}
                                cache.transform { cache in
                                    cache.merge(locations, uniquingKeysWith: {a, _ in a})
                                }
                                promise(.success(locations))
                            }
                        }
                    }
                    .replaceError(with: [])
                    .eraseToAnyPublisher()
                }
                else {
                    return Just([]).eraseToAnyPublisher()
                }
            }

            return structureIDs.publisher.flatMap { id in
                totalProgress.performAsCurrent(withPendingUnitCount: 1, totalUnitCount: 100) { p in
                    esi.universe.structures().structureID(id).get {
                        p.completedUnitCount = Int64($0.fractionCompleted * 100)
                        progress?(totalProgress)
                    }.flatMap { structure in
                        Future<(Int64, EVELocation)?, AFError> { promise in
                            managedObjectContext.perform {
                                let location = EVELocation(structure.value, id: id, managedObjectContext: managedObjectContext)
                                cache.transform { cache in
                                    cache[id] = location
                                }
                                promise(.success((id, location)))
                            }
                        }
                    }.replaceError(with: nil)
                        .compactMap{$0}
                }
                }.collect()
                .merge(with: names, Just(stations))
                .reduce([], +)
                .map {
                    Dictionary($0) { (a, _) in a }
            }.eraseToAnyPublisher()
		}.eraseToAnyPublisher()
    }
}
