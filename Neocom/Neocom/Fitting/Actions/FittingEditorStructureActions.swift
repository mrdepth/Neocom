//
//  FittingEditorStructureActions.swift
//  Neocom
//
//  Created by Artem Shimanski on 4/22/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import CoreData
import EVEAPI

struct FittingEditorStructureActions: View {
    @EnvironmentObject private var structure: DGMStructure
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @State private var isAreaEffectsPresented = false
    @State private var isCharactersPresented = false
    @State private var isDamagePatternsPresented = false
    @State private var isActivityPresented = false
    @EnvironmentObject private var sharedState: SharedState
    
    private var areaEffects: some View {
        AreaEffects { type in
            self.structure.area = try? DGMArea(typeID: DGMTypeID(type.typeID))
            self.isAreaEffectsPresented = false
        }
    }

    var body: some View {
        let type = structure.type(from: managedObjectContext)
        let area = structure.area?.type(from: managedObjectContext)
        return List {
            type.map {type in
                Section(header: Text("STRUCTURE")) {
                    TextField("Structure Name", text: $structure.name)
                    NavigationLink(destination: TypeInfo(type: type)) {
                        TypeCell(type: type)
                    }
                }
            }
            Section(header: Text("DAMAGE PATTERN")) {
                Button(action: {self.isDamagePatternsPresented = true}) {
                    DamageVectorView(damage: structure.damagePattern).frame(height: 30)
                    .contentShape(Rectangle())
                }
            }
            Section(header: Text("AREA EFFECTS")) {
                NavigationLink(destination: areaEffects, isActive: $isAreaEffectsPresented) {
                    if area != nil {
                        TypeCell(type: area!)
                    }
                    else {
                        Text("None")
                    }
                }
            }
            
            Section {
                Button("Share") {
                    self.isActivityPresented = true
                }.frame(maxWidth: .infinity)
            }
        }
        .listStyle(GroupedListStyle())
        .sheet(isPresented: $isDamagePatternsPresented) {
            NavigationView {
                DamagePatterns { vector in
                    self.structure.damagePattern = vector
                    self.isDamagePatternsPresented = false
                }.navigationBarItems(leading: BarButtonItems.close {
                    self.isDamagePatternsPresented = false
                })
            }.modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
        }
        .activityView(isPresented: $isActivityPresented, activityItems: [LoadoutActivityItem(ships: [structure.loadout], managedObjectContext: managedObjectContext)], applicationActivities: [InGameActivity(environment: environment, sharedState: sharedState)])
        .navigationBarTitle("Actions")
    }
}

private struct FittingEditorActionsCharacterCell: View {
    var url: URL?
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    var body: some View {
        let account = url.flatMap{DGMCharacter.account(from: $0)}.flatMap{try? managedObjectContext.fetch($0).first}
        let level = url.flatMap{DGMCharacter.level(from: $0)}
        
        return Group {
            if account != nil {
                FittingCharacterAccountCell(account: account!)
            }
            else if level != nil {
                FittingCharacterLevelCell(level: level!)
            }
            else {
                FittingCharacterLevelCell(level: 0)
            }
        }
    }
}

struct FittingEditorStructureActions_Previews: PreviewProvider {
    static var previews: some View {
        return NavigationView {
            FittingEditorStructureActions()
        }
        .environmentObject(DGMStructure.testKeepstar())
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())

    }
}
