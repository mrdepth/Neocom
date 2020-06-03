//
//  DamagePatternsCustom.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import Expressible
import CoreData

struct DamagePatternsCustom: View {
    var onSelect: (DGMDamageVector) -> Void
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \DamagePattern.name, ascending: true)])
    private var damagePatterns: FetchedResults<DamagePattern>


    var body: some View {
        Section(header: Text("CUSTOM")) {
            ForEach(damagePatterns, id: \.objectID) { row in
                CustomDamagePatternCell(damagePattern: row, onSelect: self.onSelect)
            }.onDelete { (indices) in
                indices.map{self.damagePatterns[$0]}.forEach {$0.managedObjectContext?.delete($0)}
            }
            NewDamagePatternButton()
        }
    }
}

struct CustomDamagePatternCell: View {
    var damagePattern: DamagePattern
    var onSelect: (DGMDamageVector) -> Void
    @Environment(\.editMode) private var editMode
    @Environment(\.self) private var environment
    @State private var selectedDamagePattern: DamagePattern?
    @EnvironmentObject private var sharedState: SharedState
    
    private func action() {
        if editMode?.wrappedValue == .active {
            self.selectedDamagePattern = damagePattern
        }
        else {
            self.onSelect(damagePattern.damageVector)
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                if damagePattern.name?.isEmpty == false {
                    Text(damagePattern.name!)
                }
                else {
                    Text("Unnamed").italic()
                }
                DamageVectorView(damage: damagePattern.damageVector)
            }.contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
        .sheet(item: $selectedDamagePattern) { pattern in
            NavigationView {
                DamagePatternEditor(damagePattern: pattern) {
                    self.selectedDamagePattern = nil
                }
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct NewDamagePatternButton: View {
    @State private var selectedDamagePattern: DamagePattern?
    @Environment(\.self) private var environment
    @Environment(\.managedObjectContext) private var managedObjectContext
    @EnvironmentObject private var sharedState: SharedState
    
    var body: some View {
        Button(action: {
            self.selectedDamagePattern = DamagePattern(entity: NSEntityDescription.entity(forEntityName: "DamagePattern", in: self.managedObjectContext)!, insertInto: nil)
            self.selectedDamagePattern?.damageVector = .omni
        }) {
            Text("Add New Pattern").frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(BorderlessButtonStyle())
        .sheet(item: $selectedDamagePattern) { pattern in
            NavigationView {
                DamagePatternEditor(damagePattern: pattern) {
                    self.selectedDamagePattern = nil
                }
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct DamagePatternsCustom_Previews: PreviewProvider {
    static var previews: some View {
        if (try? Storage.sharedStorage.persistentContainer.viewContext.from(DamagePattern.self).count()) == 0 {
            let pattern = DamagePattern(context: Storage.sharedStorage.persistentContainer.viewContext)
            pattern.name = "Pattern1"
            pattern.em = 2
            pattern.thermal = 1
        }
        
        return NavigationView {
            List {
                DamagePatternsCustom { _ in}
            }.listStyle(GroupedListStyle())
            .navigationBarItems(trailing: EditButton())
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())

    }
}
