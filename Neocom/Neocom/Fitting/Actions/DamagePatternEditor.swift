//
//  DamagePatternEditor.swift
//  Neocom
//
//  Created by Artem Shimanski on 3/18/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Dgmpp
import CoreData

fileprivate struct CustomAlignmentID: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[VerticalAlignment.center]
    }
}

struct DamagePatternEditor: View {
    var damagePattern: DamagePattern
    var completion: () -> Void
    @State private var damageVector: DGMDamageVector
    @State private var name: String
    @Environment(\.managedObjectContext) private var managedObjectContext
    
    init(damagePattern: DamagePattern, completion: @escaping () -> Void) {
        self.damagePattern = damagePattern
        self.completion = completion
        _damageVector = State(initialValue: damagePattern.damageVector.normalized)
        _name = State(initialValue: damagePattern.name ?? "")
    }
    
    private func save() {
        if damagePattern.managedObjectContext == nil {
            managedObjectContext.insert(damagePattern)
        }
        damagePattern.damageVector = damageVector
        damagePattern.name = name
        completion()
    }
    
    private func cancel() {
        completion()
    }

    var body: some View {
        VStack {
            TextField("Name", text: $name).textFieldStyle(RoundedBorderTextFieldStyle())
            DamagePatternControl(damageVector: $damageVector).alignmentGuide(VerticalAlignment(CustomAlignmentID.self)) {$0[VerticalAlignment.bottom]}
        }.padding()
            .overlay(VStack(spacing: 0) {
                Divider()
                Spacer()
                Divider()
            })
            .background(Color(.systemBackground))
            .frame(maxHeight: .infinity, alignment: Alignment(horizontal: .center, vertical: VerticalAlignment(CustomAlignmentID.self)))
            .navigationBarTitle(Text("Damage Pattern"))
            .navigationBarItems(leading: Button("Cancel", action: cancel),
                                trailing: Button(action: save) { Text("Save").fontWeight(.semibold)})
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

struct DamagePatternEditor_Previews: PreviewProvider {
    static var previews: some View {
        let damagePattern = DamagePattern(entity: NSEntityDescription.entity(forEntityName: "DamagePattern", in: Storage.testStorage.persistentContainer.viewContext)!, insertInto: nil)
        damagePattern.em = 0.25
        damagePattern.thermal = 0.25
        damagePattern.kinetic = 0.25
        damagePattern.explosive = 0.25
        
        
        return NavigationView {
            return DamagePatternEditor(damagePattern: damagePattern) {}
        }.modifier(ServicesViewModifier.testModifier())
    }
}
