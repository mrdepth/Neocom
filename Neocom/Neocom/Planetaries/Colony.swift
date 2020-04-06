//
//  Colony.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/30/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Dgmpp
import Expressible

struct Colony: View {
    var planet: ESI.Planets.Element
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.esi) private var esi
    @Environment(\.account) private var account
    @ObservedObject private var colony = Lazy<PlanetLoader>()

    var body: some View {
        let planetName = try? managedObjectContext.from(SDEMapPlanet.self).filter(/\SDEMapPlanet.planetID == Int32(self.planet.planetID)).first()?.planetName
        let result = self.account.map { account in
            self.colony.get(initial: PlanetLoader(esi: esi, characterID: account.characterID, planet: self.planet))
        }
        
        let error = result?.result?.error
        let planet = result?.result?.value
        
        return List {
            if planet != nil {
                ColonyContent(planet: planet!)
            }
        }.listStyle(GroupedListStyle())
            .overlay(result == nil ? Text(RuntimeError.noAccount).padding() : nil)
            .overlay(error.map{Text($0)})
            .navigationBarTitle(planetName.map{Text($0)} ?? Text("Planetaries"))
    }
}

struct ColonyContent: View {
    var planet: DGMPlanet
    var body: some View {
        let facilities = planet.facilities.sorted{$0.sortDescriptor < $1.sortDescriptor}
        return ForEach(facilities, id: \.identifier) { facility in
            Group {
                if facility is DGMExtractorControlUnit {
                    ExtractorSection(extractor: facility as! DGMExtractorControlUnit)
                }
                else if facility is DGMFactory {
                    FactorySection(factory: facility as! DGMFactory)
                }
                else if facility is DGMStorage {
                    StorageSection(storage: facility as! DGMStorage)
                }
            }
        }
    }
}

struct Colony_Previews: PreviewProvider {
    static var previews: some View {
        let planet = DGMPlanet.testPlanet()
        planet.run()
        return NavigationView {
            List {
                ColonyContent(planet: planet)
            }.listStyle(GroupedListStyle())
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(planet)
    }
}
