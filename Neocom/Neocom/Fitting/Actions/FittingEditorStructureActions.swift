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
    @ObservedObject var structure: DGMStructure
    var completion: () -> Void
    
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @State private var isAreaEffectsPresented = false
    @State private var isCharactersPresented = false
    @State private var isDamagePatternsPresented = false
    @State private var isActivityPresented = false
    @EnvironmentObject private var sharedState: SharedState
    @EnvironmentObject private var project: FittingProject
    
    private var areaEffects: some View {
        AreaEffects { type in
            self.structure.area = try? DGMArea(typeID: DGMTypeID(type.typeID))
            self.isAreaEffectsPresented = false
        }
    }
    
    private var saveButton: some View {
        Group {
            if project.loadouts[structure] == nil {
                Button(action: {
                    self.project.save()
                    self.completion()
                }) {
                    Text("Save").padding(.horizontal, 8).contentShape(Rectangle())
                }
            }
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
                Button(NSLocalizedString("Share", comment: "")) {
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
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .activityView(isPresented: $isActivityPresented, activityItems: [LoadoutActivityItem(ships: [structure.loadout], managedObjectContext: managedObjectContext)], applicationActivities: [InGameActivity(environment: environment, sharedState: sharedState)])
        .navigationBarTitle(Text("Actions"))
        .navigationBarItems(leading: BarButtonItems.close(completion), trailing: saveButton)
    }
}

#if DEBUG
struct FittingEditorStructureActions_Previews: PreviewProvider {
    static var previews: some View {
        return NavigationView {
            FittingEditorStructureActions(structure: DGMStructure.testKeepstar()) {}
        }
        .modifier(ServicesViewModifier.testModifier())

    }
}
#endif
