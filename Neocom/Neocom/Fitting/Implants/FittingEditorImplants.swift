//
//  FittingEditorImplants.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible

struct FittingEditorImplants: View {
    @ObservedObject var ship: DGMShip
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.typePicker) private var typePicker
    
    
    private enum Row: Identifiable {
        case implant(DGMImplant, slot: Int)
        case booster(DGMBooster, slot: Int)
        case slot(Int)
        
        var id: AnyHashable {
            slot
        }
        
        var implant: DGMImplant? {
            switch self {
            case let .implant(implant, _):
                return implant
            default:
                return nil
            }
        }

        var booster: DGMBooster? {
            switch self {
            case let .booster(booster, _):
                return booster
            default:
                return nil
            }
        }
        
        var slot: Int {
            switch self {
            case let .implant(_, slot):
                return slot
            case let .booster(_, slot):
                return slot
            case let .slot(slot):
                return slot
            }
        }
    }
    
    var body: some View {
        let pilot = ship.parent as? DGMCharacter
        let implants = Dictionary(pilot?.implants.map{($0.slot, $0)} ?? []) {a, _ in a}
        
        let implantRows: [Row] = stride(from: 1, through: 10, by: 1).map { i in
            implants[i].map{.implant($0, slot: i)} ?? .slot(i)
        }
        
        let boosterSlots = (try? managedObjectContext.from(SDEDgmppItemCategory.self).filter(/\SDEDgmppItemCategory.category == SDEDgmppItemCategoryID.booster.rawValue).fetch().map{Int($0.subcategory)})?.sorted() ?? [1,2,3,4]

        let boosters = Dictionary(pilot?.boosters.map{($0.slot, $0)} ?? []) {a, _ in a}
        let boosterRows: [Row] = boosterSlots.map { i in
            boosters[i].map{.booster($0, slot: i)} ?? .slot(i)
        }
        
        return List {
            Section(header: Text("IMPLANTS")) {
                ForEach(implantRows) { row in
                    if row.implant != nil {
                        FittingImplantCell(implant: row.implant!)
                    }
                    else {
                        FittingImplantSlot(ship: self.ship, slot: row.slot, category: .implant)
                    }
                }
            }
            Section(header: Text("BOOSTERS")) {
                ForEach(boosterRows) { row in
                    if row.booster != nil {
                        FittingBoosterCell(booster: row.booster!)
                    }
                    else {
                        FittingImplantSlot(ship: self.ship, slot: row.slot, category: .booster)
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
}

#if DEBUG
struct FittingEditorImplants_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        
        return FittingEditorImplants(ship: gang.pilots[0].ship!)
            .environmentObject(gang)
            .modifier(ServicesViewModifier.testModifier())
    }
}
#endif
