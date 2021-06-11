//
//  FittingEditorModulesPrice.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/13/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import CoreData

struct FittingEditorModulesPrice: View {
    @ObservedObject var ship: DGMShip
    var prices: [Int: Double]
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    let formatter = UnitFormatter(unit: .isk, style: .long)
    
    private func price(for type: SDEInvType) -> some View {
        let price = prices[Int(type.typeID)] ?? 0
        
        return Group {
            if price > 0 {
                Text(formatter.string(from: price))
            }
            else {
                Text("No Price")
            }
        }
    }
    
    var body: some View {
        let types = ship.modules.compactMap{$0.type(from: managedObjectContext)}.sorted{$0.typeName! < $1.typeName!}
        
        return List {
            ForEach(types, id: \.objectID) { type in
                NavigationLink(destination: TypeInfo(type: type)) {
                    HStack {
                        Icon(type.image).cornerRadius(4)
                        VStack(alignment: .leading) {
                            Text(type.typeName!)
                            self.price(for: type).modifier(SecondaryLabelModifier())
                        }
                    }
                }
            }
        }.listStyle(GroupedListStyle()).navigationBarTitle(Text("Modules"))
    }
}

#if DEBUG
struct FittingEditorModulesPrice_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            FittingEditorModulesPrice(ship: gang.pilots.first!.ship!, prices: [:])
        }
        .environmentObject(gang)
        .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
