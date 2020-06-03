//
//  FittingEditorFuelStats.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/10/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible
import EVEAPI

struct FittingEditorFuelStats: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    @ObservedObject var ship: DGMShip
    
    let formatter = UnitFormatter(unit: .none, style: .short)
    
    private func header(text: Text, image: Image) -> some View {
        HStack {
            Icon(image, size: .small)
            text
            }.frame(maxWidth: .infinity).offset(x: -16)
    }
    
    private func cell(_ damage: Double) -> some View {
        Text(formatter.string(from: damage)).fixedSize().frame(maxWidth: .infinity)
    }

    var body: some View {
        let structure = ship as? DGMStructure
        let fuelUse = structure?.fuelUse ?? DGMFuelUnitsPerHour(0)
//        let perHour = UnitFormatter.localizedString(from: fuelUse * DGMHours(1), unit: .none, style: .long)
        let perDay = UnitFormatter.localizedString(from: fuelUse * DGMDays(1), unit: .none, style: .long)
        
        return Group {
            if structure != nil {
                Section(header: Text("FUEL")) {
                    HStack {
                        Icon(Image("fuel"))
                        Text("\(perDay) units/day")
                    }
                    
                }
            }
        }
    }
}

struct FittingEditorFuelStats_Previews: PreviewProvider {
    static var previews: some View {
        return List {
            FittingEditorFuelStats(ship: DGMStructure.testKeepstar())
        }.listStyle(GroupedListStyle())
            .environmentObject(PricesData(esi: ESI()))
            .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
    }
}


