//
//  IncursionSolarSystems.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible

struct IncursionSolarSystems: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var incursion: ESI.Incursion
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SDEMapSolarSystem.solarSystemName, ascending: true)])
    private var solarSystems: FetchedResults<SDEMapSolarSystem>
    
    init(incursion: ESI.Incursion) {
        self.incursion = incursion
        _solarSystems = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SDEMapSolarSystem.solarSystemName, ascending: true)],
                                     predicate: (/\SDEMapSolarSystem.solarSystemID).in(incursion.infestedSolarSystems).predicate())
    }
    
    var body: some View {
        List(solarSystems, id: \.objectID) { solarSystem in
            Text(EVELocation(solarSystem: solarSystem, id: Int64(solarSystem.solarSystemID)))
        }.listStyle(GroupedListStyle())
        .navigationBarTitle(Text("Infested Solar Systems"))
    }
}

struct IncursionSolarSystems_Previews: PreviewProvider {
    static var previews: some View {
        let context = Storage.sharedStorage.persistentContainer.viewContext
        let constellation = try! context.from(SDEMapConstellation.self).first()!
        let faction = try! context.from(SDEChrFaction.self).first()!
        let solarSystem = try! context.from(SDEMapSolarSystem.self).first()!
        return NavigationView {
            IncursionSolarSystems(incursion: ESI.Incursion(constellationID: Int(constellation.constellationID),
                                                           factionID: Int(faction.factionID),
                                                           hasBoss: true,
                                                           infestedSolarSystems: [Int(solarSystem.solarSystemID)],
                                                           influence: 0.75,
                                                           stagingSolarSystemID: Int(solarSystem.solarSystemID),
                                                           state: .mobilizing,
                                                           type: "Type"))
        }
        .environment(\.managedObjectContext, context)
    }
}
