//
//  FittingsLoader.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/6/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import CoreData
import Expressible
import EVEAPI
import Alamofire

class FittingsLoader: ObservableObject {
    
    struct Section: Identifiable  {
        var title: String?
        var id: Int32?
        struct Loadout: Identifiable {
            var typeName: String
            var fitting: ESI.Fittings.Element
            
            var id: Int {return fitting.fittingID}
        }
        var loadouts: [Loadout]
    }
    
    @Published var fittings: Result<[Section], AFError>?
    
    private var subscription: AnyCancellable?
    
    init(esi: ESI, characterID: Int64, managedObjectContext: NSManagedObjectContext) {
        subscription = esi.characters.characterID(Int(characterID)).fittings().get()
            .map{$0.value}
            .receive(on: managedObjectContext)
            .map { fittings -> [Section] in
                var sections = [Int32?: Section]()
                for fitting in fittings {
                    let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(fitting.shipTypeID)).first()
                    let groupID = type?.group?.groupID
                    sections[groupID, default: Section(title: type?.group?.groupName, id: groupID, loadouts: [])].loadouts.append(Section.Loadout(typeName: type?.typeName ?? "", fitting: fitting))
                }
                return sections.values
                    .map{Section(title: $0.title, id: $0.id, loadouts: $0.loadouts.sorted{($0.typeName, $0.fitting.name) < ($1.typeName, $1.fitting.name)})}
                    .sorted{($0.title ?? "") < ($1.title ?? "")}
        }
        .asResult()
        .receive(on: RunLoop.main)
        .sink { [weak self] fittings in
            self?.fittings = fittings
        }
    }
    
    func delete(fittingIDs: Set<Int>) {
        guard var fittings = fittings?.value else {return}
        for i in fittings.indices {
            fittings[i].loadouts.removeAll{fittingIDs.contains($0.fitting.fittingID)}
        }
        
        self.fittings = .success(fittings.filter{!$0.loadouts.isEmpty})
    }

}
