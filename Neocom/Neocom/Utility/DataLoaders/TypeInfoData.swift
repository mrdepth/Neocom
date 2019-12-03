//
//  TypeInfoData.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/3/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import EVEAPI
import CoreData

class TypeInfoData: ObservableObject {
    @Published var renderImage: UIImage?
    @Published var pilot: Pilot?
    
    enum Row: Identifiable {
        var id: NSManagedObjectID {
            switch self {
            case let .simple(id, _, _, _):
                return id
            }
        }
        
        case simple(NSManagedObjectID, UIImage?, String, String?)
    }
    
    init(type: SDEInvType, esi: ESI, characterID: Int64?, managedObjectContext: NSManagedObjectContext) {
        esi.image.type(Int(type.typeID), size: .size1024).receive(on: RunLoop.main).sink(receiveCompletion: {_ in}) { [weak self] (result) in
            self?.renderImage = result
        }.store(in: &subscriptions)
        
        if let characterID = characterID {
            Pilot.load(esi.characters.characterID(Int(characterID)), in: managedObjectContext)
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: {_ in }) { [weak self] (result) in
                    self?.pilot = result
            }.store(in: &subscriptions)
        }
        
        $pilot.flatMap { pilot in
            Future { promise in
                managedObjectContext.perform {
                    promise(.success(1))
                }
            }
        }.receive(on: RunLoop.main).sink { result in
        }.store(in: &subscriptions)
    }
    
    private var subscriptions = Set<AnyCancellable>()
}
