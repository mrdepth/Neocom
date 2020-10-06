//
//  WormholeCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct WormholeCell: View {
    var wormhole: SDEWhType
    
    private var whMass: some View {
        Text("\(UnitFormatter.localizedString(from: wormhole.maxJumpMass, unit: .none, style: .long)) / \(UnitFormatter.localizedString(from: wormhole.maxStableMass, unit: .kilogram, style: .long))").modifier(SecondaryLabelModifier())
    }

    var body: some View {
        HStack {
            (wormhole.type?.image).map{Icon($0).cornerRadius(4)}
            VStack(alignment: .leading) {
                wormhole.type?.typeName.map{Text($0)} ?? Text("Unnamed")
                if wormhole.maxStableMass > 0 {
                    whMass
                }
            }
        }
    }
}

struct WormholeCell_Previews: PreviewProvider {
    static var previews: some View {
        let wh = try! Storage.testStorage.persistentContainer.viewContext.from(SDEWhType.self).first()!
        return WormholeCell(wormhole: wh)
    }
}
