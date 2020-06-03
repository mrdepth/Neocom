//
//  PlanetCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/1/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible

struct PlanetCell: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var planet: ESI.Planets.Element
    
    var body: some View {
        let mapPlanet = try? managedObjectContext.from(SDEMapPlanet.self).filter(/\SDEMapPlanet.planetID == Int32(planet.planetID)).first()
        
        return HStack {
            mapPlanet?.type.map{Icon($0.image).cornerRadius(4)}
            VStack(alignment: .leading) {
                mapPlanet?.planetName.map{Text($0)} ?? Text("Unknown")
                mapPlanet?.type?.typeName.map{Text($0)}?.modifier(SecondaryLabelModifier())
            }
        }
    }
}

struct PlanetCell_Previews: PreviewProvider {
    static var previews: some View {
        let planet = try! ESI.jsonDecoder.decode(ESI.Planets.self, from: NSDataAsset(name: "planetsList")!.data)[0]
        return PlanetCell(planet: planet)
            .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}
