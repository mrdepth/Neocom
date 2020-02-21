//
//  OptimalAttributes.swift
//  Neocom
//
//  Created by Artem Shimanski on 2/5/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct OptimalAttributes: View {
    var pilot: Pilot
    var trainingQueue: TrainingQueue
    
    private static let rows = [(Text("Intelligence", comment: ""), Image("intelligence"), \Pilot.Attributes.intelligence),
                (Text("Memory", comment: ""), Image("memory"), \Pilot.Attributes.memory),
                (Text("Perception", comment: ""), Image("perception"), \Pilot.Attributes.perception),
                (Text("Willpower", comment: ""), Image("willpower"), \Pilot.Attributes.willpower),
                (Text("Charisma", comment: ""), Image("charisma"), \Pilot.Attributes.charisma)]

    private func section(for attributes: Pilot.Attributes) -> some View {
        ForEach(0..<5) { i in
            HStack {
                Icon(Self.rows[i].1)
                VStack(alignment: .leading) {
                    Self.rows[i].0
                    Text("\(attributes[keyPath: Self.rows[i].2]) + \(self.pilot.augmentations[keyPath: Self.rows[i].2])").modifier(SecondaryLabelModifier())
                }
            }
        }
    }
    
    var body: some View {
        let optimal = Pilot.Attributes(optimalFor: trainingQueue)
        let trainingTime = trainingQueue.trainingTime()
        let optimalTrainingTime = trainingQueue.trainingTime(with: optimal + pilot.augmentations)
        let dt = trainingTime - optimalTrainingTime
        return List {
            Section(header:  Text("OPTIMAL: \(TimeIntervalFormatter.localizedString(from: optimalTrainingTime, precision: .seconds).uppercased())"),
                    footer: (dt > 0 ? Text("\(TimeIntervalFormatter.localizedString(from: dt, precision: .seconds)) better.\n") : Text("")) + Text("Based on current training queue and skill plan.")) {
                section(for: optimal)
            }
            Section(header: Text("CURRENT: \(TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds).uppercased())")) {
                section(for: pilot.attributes)
            }
        }.listStyle(GroupedListStyle()).navigationBarTitle("Attributes")
    }
}

struct OptimalAttributes_Previews: PreviewProvider {
    static var previews: some View {
        var pilot = Pilot.empty
        pilot.augmentations = Pilot.Attributes(intelligence: 4, memory: 4, perception: 4, willpower: 4, charisma: 4)
        let trainingQueue = TrainingQueue(pilot: pilot)
        let skill = try! AppDelegate.sharedDelegate.persistentContainer.viewContext
            .from(SDEInvType.self)
            .filter(/\SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue)
            .first()!
        trainingQueue.add(skill, level: 5)
        return NavigationView {
            OptimalAttributes(pilot: pilot, trainingQueue: trainingQueue)
            .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
        }
    }
}
