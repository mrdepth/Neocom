//
//  LoyaltyOfferRequirement.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/28/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import EVEAPI
import Expressible

struct LoyaltyOfferRequirement: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var requirement: ESI.LoyaltyOfferRequirement
    
    var body: some View {
        let type = try? managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(requirement.typeID)).first()
        
        return HStack(spacing: 4) {
            type.map{Icon($0.image, size: .small).cornerRadius(4)}
            type?.typeName.map{Text($0)} ?? Text("Unknown")
            if requirement.quantity > 1 {
                Text("x\(UnitFormatter.localizedString(from: requirement.quantity, unit: .none, style: .long))")
            }
        }.modifier(SecondaryLabelModifier())
    }
}

struct LoyaltyOfferRequirement_Previews: PreviewProvider {
    static var previews: some View {
        LoyaltyOfferRequirement(requirement: ESI.LoyaltyOfferRequirement(quantity: 10, typeID: 645))
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
