//
//  FittingCargoCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/17/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import EVEAPI

struct FittingCargoCell: View {
    @ObservedObject var ship: DGMShip
    @ObservedObject var cargo: DGMCargo
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var prices: PricesData
    
    var body: some View {
        let type = cargo.type(from: managedObjectContext)
        let price = prices.prices?.value?[cargo.typeID] ?? 0

        return HStack {
            type.map{Icon($0.image).cornerRadius(4)}
            VStack(alignment: .leading) {
                type?.typeName.map{Text($0)} ?? Text("Unknown")
                HStack {
                    CargoVolume(ship: ship, cargo: cargo)
                    if price > 0 {
                        Text("| \(UnitFormatter.localizedString(from: price * Double(cargo.quantity), unit: .isk, style: .short))")
                    }
                }.modifier(SecondaryLabelModifier())
            }
            Spacer()
            Text("x\(UnitFormatter.localizedString(from: cargo.quantity, unit: .none, style: .long))").fontWeight(.semibold).modifier(SecondaryLabelModifier())
        }.contentShape(Rectangle())
    }
}

struct CargoVolume: View {
    @ObservedObject var ship: DGMShip
    @ObservedObject var cargo: DGMCargo
    
    var body: some View {
        let p = cargo.volume / max(ship.cargoCapacity, 1)
        return Text(UnitFormatter.localizedString(from: cargo.volume, unit: .cubicMeter, style: .short)) + Text(" (\(UnitFormatter.localizedString(from: Int(p * 100), unit: .none, style: .long))%)").foregroundColor(p > 1 ? Color.red : nil)
    }
}


struct FittingCargoCell_Previews: PreviewProvider {
    static var previews: some View {
        let cargo = try! DGMCargo(typeID: 3154)
        cargo.quantity = 10
        return List {
            FittingCargoCell(ship: DGMShip.testDominix(), cargo: cargo)
        }.listStyle(GroupedListStyle())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environmentObject(PricesData(esi: ESI()))
        
    }
}
