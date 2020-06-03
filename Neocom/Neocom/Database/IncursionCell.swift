//
//  IncursionCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible

struct IncursionCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var incursion: ESI.Incursion
    
    var body: some View {
        let faction = try? managedObjectContext.from(SDEChrFaction.self).filter(/\SDEChrFaction.factionID == Int32(incursion.factionID)).first()
        let stagingSolarSystem = try? managedObjectContext.from(SDEMapSolarSystem.self).filter(/\SDEMapSolarSystem.solarSystemID == Int32(incursion.stagingSolarSystemID)).first()

        return VStack(alignment: .leading) {
            HStack {
                Avatar(corporationID: Int64(incursion.factionID), size: .size256).frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    faction?.factionName.map{Text($0)} ?? Text("Unknown")
                    HStack(spacing: 4) {
                        Text("\(incursion.state.title): ")
                        Text(EVELocation(solarSystem: stagingSolarSystem, id: Int64(incursion.stagingSolarSystemID)))
                    }.modifier(SecondaryLabelModifier())
                    Text("\(stagingSolarSystem?.constellation?.constellationName ?? "") / \(stagingSolarSystem?.constellation?.region?.regionName ?? "")").modifier(SecondaryLabelModifier())
                }
            }
            HStack {
                HStack {
                    Text("Warzone Control:")
                    Text("\(Int(incursion.influence * 100))%")
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .background(ProgressView(progress: Float(incursion.influence)).accentColor(.skyBlueBackground))
                if incursion.hasBoss {
                    Icon(Image("incursionBoss"), size: .small)
                }
            }
        }
    }
}

#if DEBUG
struct IncursionCell_Previews: PreviewProvider {
    static var previews: some View {
        let context = Storage.sharedStorage.persistentContainer.viewContext
        let constellation = try! context.from(SDEMapConstellation.self).first()!
        let faction = try! context.from(SDEChrFaction.self).first()!
        let solarSystem = try! context.from(SDEMapSolarSystem.self).first()!
        
        return List {
            IncursionCell(incursion: ESI.Incursion(constellationID: Int(constellation.constellationID),
                                                   factionID: Int(faction.factionID),
                                                   hasBoss: true,
                                                   infestedSolarSystems: [Int(solarSystem.solarSystemID)],
                                                   influence: 0.75,
                                                   stagingSolarSystemID: Int(solarSystem.solarSystemID),
                                                   state: .mobilizing,
                                                   type: "Type"))
        }
        .listStyle(GroupedListStyle())
        .environment(\.managedObjectContext, context)
        .environmentObject(SharedState.testState())
    }
}
#endif
