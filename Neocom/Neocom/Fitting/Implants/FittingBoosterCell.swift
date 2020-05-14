//
//  FittingBoosterCell.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/9/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingBoosterCell: View {
    @ObservedObject var booster: DGMBooster
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @State private var isActionsPresented = false

    var body: some View {
        let type = booster.type(from: managedObjectContext)
        return Group {
            HStack {
                Button(action: {self.isActionsPresented = true}) {
                    HStack {
                        if type != nil {
                            TypeCell(type: type!)
                        }
                        else {
                            Icon(Image("implant"))
                            Text("Unknown")
                        }
                        Spacer()
                    }.contentShape(Rectangle())
                }.buttonStyle(PlainButtonStyle())
                type.map {
                    TypeInfoButton(type: $0)
                }
            }
        }.actionSheet(isPresented: $isActionsPresented) {
            ActionSheet(title: Text("Implant"), buttons: [.destructive(Text("Delete"), action: {
                (self.booster.parent as? DGMCharacter)?.remove(self.booster)
            }), .cancel()])
        }
    }
}

struct FittingBoosterCell_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let pilot = gang.pilots[0]
        let booster = pilot.boosters.first!

        return List {
            FittingBoosterCell(booster: booster)
        }.listStyle(GroupedListStyle())
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environmentObject(gang)

        
    }
}
