//
//  WormholeInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct WormholeInfo: View {
    @Environment(\.managedObjectContext) private var managedObjectContext
    var type: SDEInvType
    
    var leadsInto: some View {
        HStack {
            Icon(Image("systems"))
            VStack (alignment: .leading) {
                Text("Leads Into")
                Text(type.wormhole!.targetSystemClassDisplayName ?? "").modifier(SecondaryLabelModifier())
            }
        }
    }
    
    var maxStableTime: some View {
        let icon = try? managedObjectContext.fetch(SDEEveIcon.named(.custom("22_32_16"))).first
        let image = icon?.image?.image
        
        return HStack {
            image.map{Icon(Image(uiImage: $0))}
            VStack (alignment: .leading) {
                Text("Maximum Stable Time")
                Text(TimeIntervalFormatter.localizedString(from: TimeInterval(type.wormhole!.maxStableTime) * 60, precision: .hours))
                    .modifier(SecondaryLabelModifier())
            }
        }
    }

    var maxStableMass: some View {
        let icon = try? managedObjectContext.fetch(SDEEveIcon.named(.custom("2_64_10"))).first
        let image = icon?.image?.image
        
        return HStack {
            image.map{Icon(Image(uiImage: $0))}
            VStack (alignment: .leading) {
                Text("Maximum Stable Mass")
                Text(UnitFormatter.localizedString(from: type.wormhole!.maxStableMass, unit: .kilogram, style: .long))
                    .modifier(SecondaryLabelModifier())
            }
        }
    }

    var maxJumpMass: some View {
        HStack {
            Icon(Image("priceShip"))
            VStack (alignment: .leading) {
                Text("Maximum Jump Mass")
                Text(UnitFormatter.localizedString(from: type.wormhole!.maxJumpMass, unit: .kilogram, style: .long))
                    .modifier(SecondaryLabelModifier())
            }
        }
    }

    var maxRegeneration: some View {
        let icon = try? managedObjectContext.fetch(SDEEveIcon.named(.custom("23_64_3"))).first
        let image = icon?.image?.image
        
        return HStack {
            image.map{Icon(Image(uiImage: $0))}
            VStack (alignment: .leading) {
                Text("Maximum Mass Regeneration")
                Text(UnitFormatter.localizedString(from: type.wormhole!.maxRegeneration, unit: .kilogram, style: .long))
                    .modifier(SecondaryLabelModifier())
            }
        }
    }

    var body: some View {
        Section {
            if type.wormhole!.targetSystemClass > 0 {
                leadsInto
            }
            if type.wormhole!.maxStableTime > 0 {
                maxStableTime
            }
            if type.wormhole!.maxStableMass > 0 {
                maxStableMass
            }
            if type.wormhole!.maxJumpMass > 0 {
                maxJumpMass
            }
            if type.wormhole!.maxRegeneration > 0 {
                maxRegeneration
            }
        }
    }
}

#if DEBUG
struct WormholeInfo_Previews: PreviewProvider {
    static var previews: some View {
        let wh = try! Storage.testStorage.persistentContainer.viewContext.from(SDEWhType.self).first()!
        return NavigationView {
            List {
                WormholeInfo(type: wh.type!)
            }.listStyle(GroupedListStyle())
        }.modifier(ServicesViewModifier.testModifier())
    }
}
#endif
