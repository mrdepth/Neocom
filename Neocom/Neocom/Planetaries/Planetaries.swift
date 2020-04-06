//
//  Planetaries.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/1/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Alamofire
import Expressible

struct Planetaries: View {
    @ObservedObject private var planets = Lazy<DataLoader<[PlanetariesSection], AFError>>()
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    private struct PlanetariesSection: Identifiable {
        struct Row: Identifiable {
            var planet: ESI.Planets.Element
            var title: String?
            var id: Int
        }
        var title: String?
        var rows: [Row]
        var id: Int32?
    }
//\u{2063}Unknown Location
    private func planets(characterID: Int64) -> DataLoader<[PlanetariesSection], AFError> {
        let planets = esi.characters.characterID(Int(characterID)).planets().get().map{$0.value}
            
            .receive(on: RunLoop.main)
            .map { planets -> [PlanetariesSection] in
                var sections = [SDEMapRegion?: PlanetariesSection]()
                planets.forEach { planet in
                    let mapPlanet = try? self.managedObjectContext.from(SDEMapPlanet.self).filter(/\SDEMapPlanet.planetID == Int32(planet.planetID)).first()
                    let region = mapPlanet?.solarSystem?.constellation?.region
                    sections[region, default: PlanetariesSection(title: region?.regionName, rows: [], id: region?.regionID)].rows.append(PlanetariesSection.Row(planet: planet, title: mapPlanet?.planetName, id: planet.planetID))
                }
                return sections.mapValues{PlanetariesSection(title: $0.title, rows: $0.rows.sorted{($0.title ?? "\u{2063}") < ($1.title ?? "\u{2063}")}, id: $0.id)}
                    .sorted{($0.key?.regionName ?? "\u{2063}") < ($1.key?.regionName ?? "\u{2063}")}
                    .map{$0.value}
        }
        return DataLoader(planets)
    }

    
    var body: some View {
        let result = account.map { account in
            self.planets.get(initial: self.planets(characterID: account.characterID))
        }
        let sections = result?.result?.value
        let error = result?.result?.error
        
        return List {
            if sections != nil {
                ForEach(sections!) { section in
                    Section(header: section.title.map{Text($0.uppercased())} ?? Text("Unknown Location")) {
                        ForEach(section.rows) { row in
                            NavigationLink(destination: Colony(planet: row.planet)) {
                                PlanetCell(planet: row.planet)
                            }
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle())
            .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay(error.map{Text($0)})
            .overlay(sections?.isEmpty == true ? Text(RuntimeError.noResult).padding() : nil)
            .navigationBarTitle(Text("Planetaries"))
    }
}

struct Planetaries_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        
        return NavigationView {
            Planetaries()
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.account, account)
        .environment(\.esi, esi)

    }
}
