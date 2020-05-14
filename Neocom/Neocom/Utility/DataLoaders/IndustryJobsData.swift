//
//  IndustryJobsData.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Combine
import Alamofire
import CoreData

class IndustryJobsData: ObservableObject {
    @Published var isLoading = false
    @Published var result: Result<(active: ESI.IndustryJobs, finished: ESI.IndustryJobs, locations: [Int64: EVELocation]), AFError>?
    
    private var esi: ESI
    private var characterID: Int64
    private var managedObjectContext: NSManagedObjectContext
    private var subscription: AnyCancellable?

    init(esi: ESI, characterID: Int64, managedObjectContext: NSManagedObjectContext) {
        self.esi = esi
        self.characterID = characterID
        self.managedObjectContext = managedObjectContext
        update(cachePolicy: .useProtocolCachePolicy)
    }
    
    func update(cachePolicy: URLRequest.CachePolicy) {
        isLoading = true
        let managedObjectContext = self.managedObjectContext
        let esi = self.esi
        let characterID = self.characterID
        
        subscription = esi.characters.characterID(Int(characterID)).industry().jobs().get(includeCompleted: true, cachePolicy: cachePolicy).flatMap { jobs -> AnyPublisher<(ESI.IndustryJobs, ESI.IndustryJobs, [Int64: EVELocation]), AFError> in
            let locationIDs = jobs.value.map{$0.outputLocationID} + jobs.value.map{$0.stationID}
            let locations = EVELocation.locations(with: Set(locationIDs), esi: esi, managedObjectContext: managedObjectContext).replaceError(with: [:])
            
            let activeStatus = Set<ESI.IndustryJobStatus>([.active, .paused])
            
            var tmp = jobs.value
            let i = tmp.partition{activeStatus.contains($0.currentStatus)}
            let active = tmp[i...].sorted{$0.endDate < $1.endDate}
            let finished = tmp[..<i].sorted{$0.endDate > $1.endDate}

            return Publishers.Zip3(Just(active), Just(finished), locations).setFailureType(to: AFError.self).eraseToAnyPublisher()
        }.asResult()
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                self?.result = result.map{(active: $0.0, finished: $0.1, locations: $0.2)}
                self?.isLoading = false
        }
    }
}
