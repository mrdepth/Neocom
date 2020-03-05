//
//  FittingModuleState.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/26/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp

struct FittingModuleState: View {
    @ObservedObject var module: DGMModuleGroup

    var body: some View {
        Picker("State", selection: $module.state) {
            ForEach(module.availableStates, id: \.self) { i in
                i.title.map{Text($0).tag($0)}
            }
        }.pickerStyle(SegmentedPickerStyle())
    }
}

struct FittingModuleState_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        let module = gang.pilots.first?.ship?.modules.first

        return NavigationView {
            List {
                FittingModuleState(module: DGMModuleGroup([module!]))
            }.listStyle(GroupedListStyle())
        }
            .environmentObject(gang)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
            .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)

    }
}
