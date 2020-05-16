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
import Combine

struct Planetaries: View {
    @ObservedObject private var planets = Lazy<DataLoader<[PlanetariesSection], AFError>, Account>()
    @EnvironmentObject private var sharedState: SharedState
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
    private func planets(characterID: Int64, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) -> AnyPublisher<[PlanetariesSection], AFError> {
        sharedState.esi.characters.characterID(Int(characterID)).planets().get().map{$0.value}
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
        }.eraseToAnyPublisher()
    }

    
    var body: some View {
        let result = sharedState.account.map { account in
            self.planets.get(account, initial: DataLoader(self.planets(characterID: account.characterID)))
        }
        let sections = result?.result?.value
        let error = result?.result?.error
        
        let list = List {
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
        
        return Group {
            if result != nil {
                list.onRefresh(isRefreshing: Binding(result!, keyPath: \.isLoading)) {
                    guard let account = self.sharedState.account else {return}
                    result?.update(self.planets(characterID: account.characterID, cachePolicy: .reloadIgnoringLocalCacheData))
                }
            }
            else {
                list
            }
        }
        .navigationBarTitle(Text("Planetaries"))
    }
}

#if DEBUG
struct Planetaries_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Planetaries()
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environmentObject(SharedState.testState())

    }
}
#endif
