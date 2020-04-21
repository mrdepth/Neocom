//
//  FittingEditorPriceStats.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/12/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import EVEAPI

struct FittingEditorPriceStats: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var prices: PricesData
    @EnvironmentObject private var ship: DGMShip
    
    private func ship(_ prices: [Int: Double]) -> Double {
        prices[ship.typeID] ?? 0
    }
    
    private func drones(_ prices: [Int: Double]) -> Double {
        ship.drones.reduce(0) {$0 + (prices[$1.typeID] ?? 0)}
    }
    
    private func charges(_ prices: [Int: Double]) -> Double {
        ship.modules.compactMap{module in module.charge.map{($0.typeID, module.charges)}}.reduce(0) {$0 + (prices[$1.0] ?? 0) * Double($1.1)}
    }

    private func modules(_ prices: [Int: Double]) -> Double {
        ship.modules.reduce(0) {$0 + (prices[$1.typeID] ?? 0)}
    }

    private func implants(_ prices: [Int: Double]) -> Double {
        (ship.parent as? DGMCharacter)?.implants.reduce(0) {$0 + (prices[$1.typeID] ?? 0)} ?? 0
    }
    
    private func boosters(_ prices: [Int: Double]) -> Double {
        (ship.parent as? DGMCharacter)?.boosters.reduce(0) {$0 + (prices[$1.typeID] ?? 0)} ?? 0
    }

    private func cargo(_ prices: [Int: Double]) -> Double {
        ship.cargo.reduce(0) {$0 + (prices[$1.typeID] ?? 0) * Double($1.quantity)}
    }

    private func cell(title: Text, image: Image, price: Double) -> some View {
        HStack {
            Icon(image).cornerRadius(4)
            VStack(alignment: .leading) {
                title
                Text(UnitFormatter.localizedString(from: price, unit: .isk, style: .long)).modifier(SecondaryLabelModifier())
            }
        }
    }
    
    var body: some View {
        let prices = self.prices.prices?.value
        
        let costs = prices.map {
            (ship($0), modules($0), drones($0), charges($0), implants($0), boosters($0), cargo($0))
        }
        
        let total = costs.map { (ship, modules, drones, charges, implants, boosters, cargo) in
            ship + modules + drones + charges + implants + boosters + cargo
        } ?? Double(0)
        
//        let total: Double = 0
        let type = ship.type(from: managedObjectContext)
        
        return costs.map { (ship, modules, drones, charges, implants, boosters, cargo) in
            Group {
                if total > 0 {
                    Section(header: Text("PRICE")) {
                        Group {
                            if ship > 0 {
                                cell(title: Text(type?.typeName ?? ""), image: type?.image ?? Image("priceShip"), price: ship)
                            }
                            if modules > 0 {
                                NavigationLink(destination: FittingEditorModulesPrice(prices: prices ?? [:])) {
                                    cell(title: Text("Modules"), image: Image("priceFitting"), price: modules)
                                }
                            }
                            if charges > 0 {
                                cell(title: Text("Charges"), image: Image("damagePattern"), price: charges)
                            }
                            if drones > 0 {
                                cell(title: Text("Drones"), image: Image("drone"), price: drones)
                            }
                            if implants > 0 {
                                cell(title: Text("Implants"), image: Image("implant"), price: implants)
                            }
                            if boosters > 0 {
                                cell(title: Text("Boosters"), image: Image("booster"), price: boosters)
                            }
                            if cargo > 0 {
                                cell(title: Text("Cargo"), image: Image("cargoBay"), price: cargo)
                            }

                            cell(title: Text("Total"), image: Image("priceTotal"), price: total)
                        }
                    }
                }
            }
        }
    }
}

struct FittingEditorPriceStats_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            List {
                FittingEditorPriceStats()
            }.listStyle(GroupedListStyle())
        }
        .environmentObject(gang.pilots.first!.ship!)
        .environmentObject(gang)
        .environmentObject(PricesData(esi: ESI()))
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environmentObject(SharedState.testState())
    }
}
