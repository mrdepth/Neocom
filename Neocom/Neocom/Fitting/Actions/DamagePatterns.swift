//
//  DamagePatterns.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import CoreData

struct DamagePatterns: View {
    var completion: (DGMDamageVector) -> Void
    @State private var isNpcPickerPresented = false
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    
    var npcPicker: some View {
        NavigationView {
            NPCPickerGroup(parent: nil) { type in
                self.completion(type.npcDPS?.normalized ?? .omni)
                self.isNpcPickerPresented = false
            }
            .navigationBarItems(leading: BarButtonItems.close {
                self.isNpcPickerPresented = false
            })
        }
        .modifier(ServicesViewModifier(environment: environment, sharedState: sharedState))
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var body: some View {
        List {
            Button(action: {self.isNpcPickerPresented = true}) {
                Text("Select NPC").frame(maxWidth: .infinity, alignment: .center).frame(height: 30)}.contentShape(Rectangle())
            
            DamagePatternsCustom(onSelect: completion)
            DamagePatternsPredefined(onSelect: completion)
        }.listStyle(GroupedListStyle())
        .navigationBarTitle("Damage Patterns")
        .navigationBarItems(trailing: EditButton())
            .sheet(isPresented: $isNpcPickerPresented) {self.npcPicker}
    }
}

struct DamagePatterns_Previews: PreviewProvider {
    static var previews: some View {
        let gang = DGMGang.testGang()
        return NavigationView {
            DamagePatterns { _ in }
        }
        .environmentObject(gang)
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
    }
}
