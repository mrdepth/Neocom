//
//  FittingEditorImplants.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingEditorImplants: View {
    @EnvironmentObject private var ship: DGMShip
    @Environment(\.managedObjectContext) var managedObjectContext
    
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
//        let implantPairs = pilot?.implants.map{}
        let implants = Dictionary(pilot?.implants.map{($0.slot, $0)} ?? []) {a, _ in a}
        
        let implantRows: [Row] = stride(from: 1, through: 10, by: 1).map { i in
            implants[i].map{.implant($0, slot: i)} ?? .slot(i)
        }
        
        return List {
            Section(header: Text("IMPLANTS")) {
                ForEach(implantRows) { row in
                    if row.implant != nil {
                        FittingImplantCell(implant: row.implant!)
                    }
                }
            }
        }.listStyle(GroupedListStyle())
    }
}

struct FittingEditorImplants_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        
        return FittingEditorImplants()
            .environmentObject(gang)
            .environmentObject(gang.pilots[0].ship!)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
    }
}
