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


//class LocationsInfo: ObservableObject {
//
//    init(locationIDs: [Int64], esi: ESI, managedObjectContext: NSManagedObjectContext) {
//    }
//}

class EVELocation {
    struct SolarSystem {
        let solarSystemID: Int
        let solarSystemName: String
        let security: Float
        
        init(_ solarSystem: SDEMapSolarSystem) {
            solarSystemID = Int(solarSystem.solarSystemID)
            solarSystemName = solarSystem.solarSystemName ?? NSLocalizedString("Unknown", comment: "")
            security = solarSystem.security
        }
    }
    
    let structureName: String?
    let solarSystem: SolarSystem?
    
    convenience init(_ station: SDEStaStation) {
        self.init(solarSystem: station.solarSystem, structureName: station.stationName)
    }
    
    convenience init(_ name: ESI.ItemName, managedObjectContext: NSManagedObjectContext) {
        if name.category == .solarSystem {
            let solarSystem = try? managedObjectContext.from(SDEMapSolarSystem.self).filter(\SDEMapSolarSystem.solarSystemID == name.id).first()
            self.init(solarSystem: solarSystem, structureName: name.name)
        }
        else {
            self.init(solarSystem: nil, structureName: name.name)
        }
    }
    
    convenience init(_ structure: ESI.StructureInfo, managedObjectContext: NSManagedObjectContext) {
        let solarSystem = try? managedObjectContext.from(SDEMapSolarSystem.self).filter(\SDEMapSolarSystem.solarSystemID == structure.solarSystemID).first()
        self.init(solarSystem: solarSystem, structureName: structure.name)
    }
    
    init(solarSystem: SDEMapSolarSystem?, structureName: String? = nil) {
        self.structureName = structureName
        self.solarSystem = solarSystem.map{SolarSystem($0)}
    }


    static func locations(with ids: Set<Int64>, esi: ESI, managedObjectContext: NSManagedObjectContext) -> AnyPublisher<[Int64: EVELocation], Never> {
        return Just(ids).receive(on: managedObjectContext).flatMap { ids -> AnyPublisher<[Int64: EVELocation], Never> in
            let structureIDs = ids.filter{$0 > Int64(Int32.max)}
            var missingIDs = ids.subtracting(structureIDs)
            let stations = (try? managedObjectContext.from(SDEStaStation.self).filter((\SDEStaStation.stationID).in(missingIDs)).fetch().map {(Int64($0.stationID), EVELocation($0))}) ?? []
            missingIDs.subtract(stations.map{$0.0})
            
            var publishers = structureIDs.map { id in
                esi.universe.structures().structureID(id).get().flatMap { structure in
                    Future { promise in
                        managedObjectContext.perform {
                            promise(.success([(id, EVELocation(structure, managedObjectContext: managedObjectContext))]))
                        }
                    }
                }.replaceError(with: []).eraseToAnyPublisher()
            }

            if !ids.isEmpty {
                let p = esi.universe.names().post(ids: ids.map{Int($0)}).flatMap { names in
                    Future { promise in
                        managedObjectContext.perform {
                            promise(.success(names.map{(Int64($0.id), EVELocation($0, managedObjectContext: managedObjectContext))}))
                        }
                    }
                }.replaceError(with: []).eraseToAnyPublisher()
                publishers.append(p)
            }
            return Publishers.MergeMany(publishers).collect().map {
                Dictionary($0.joined()) { (a, _) in a }
            }.eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}
