//
//  DamagePatternsPredefined.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/19/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import CoreData

struct DamagePatternsPredefined: View {
    var onSelect: (DGMDamageVector) -> Void
    struct Row: Identifiable {
        var name: String
        var damage: DGMDamageVector
        var id: String {return name}
    }
    
    static let patterns: [Row] = {
        return NSArray(contentsOf: Bundle.main.url(forResource: "damagePatterns", withExtension: "plist")!)?.compactMap { item -> Row? in
            guard let item = item as? [String: Any] else {return nil}
            guard let name = item["name"] as? String else {return nil}
            guard let em = item["em"] as? Double else {return nil}
            guard let thermal = item["thermal"] as? Double else {return nil}
            guard let kinetic = item["kinetic"] as? Double else {return nil}
            guard let explosive = item["explosive"] as? Double else {return nil}
            let vector = DGMDamageVector(em: em, thermal: thermal, kinetic: kinetic, explosive: explosive)
            return Row(name: name, damage: vector)
        } ?? []
    }()
    
    var body: some View {
        Section(header: Text("PREDEFINED")) {
            ForEach(DamagePatternsPredefined.patterns) { row in
                PredefinedDamagePatternCell(row: row, onSelect: self.onSelect)
            }
        }
    }
}

struct PredefinedDamagePatternCell: View {
    var row: DamagePatternsPredefined.Row
    var onSelect: (DGMDamageVector) -> Void
    @Environment(\.editMode) private var editMode
    @Environment(\.self) private var environment
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var selectedDamagePattern: DamagePattern?
    @EnvironmentObject private var sharedState: SharedState
    
    private func action() {
        if editMode?.wrappedValue == .active {
            self.selectedDamagePattern = DamagePattern(entity: NSEntityDescription.entity(forEntityName: "DamagePattern", in: self.managedObjectContext)!, insertInto: nil)
            self.selectedDamagePattern?.damageVector = self.row.damage
            self.selectedDamagePattern?.name = self.row.name
        }
        else {
            self.onSelect(row.damage)
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.name)
                DamageVectorView(damage: row.damage)
            }.contentShape(Rectangle())
        }.buttonStyle(PlainButtonStyle())
        .sheet(item: $selectedDamagePattern) { pattern in
            NavigationView {
                DamagePatternEditor(damagePattern: pattern) {
                    self.selectedDamagePattern = nil
                }.modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            }
        }
    }
}

struct DamagePatternsPredefined_Previews: PreviewProvider {
    static var previews: some View {
        return NavigationView {
            List {
                DamagePatternsPredefined { _ in}
            }.listStyle(GroupedListStyle())
                .navigationBarItems(trailing: EditButton())
        }
        .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)

    }
}
