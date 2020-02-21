//
//  BlueprintActivityRequiredSkills.swift
//  Neocom
//
//  Created by Artem Shimanski on 12/30/19.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible

struct BlueprintActivityRequiredSkills: View {
    @Environment(\.account) var account
    @State private var isFinished = false
    
    var activity: SDEIndActivity
    var pilot: Pilot?
    
    private var trainingQueue: TrainingQueue
    
    init(activity: SDEIndActivity, pilot: Pilot? = nil) {
        self.activity = activity
        self.pilot = pilot
        trainingQueue = TrainingQueue(pilot: pilot ?? .empty)
        trainingQueue.addRequiredSkills(for: activity)
    }
    
    private var trailingButton: some View {
        AddToSkillPlanButton(trainingQueue: trainingQueue)
    }
    
    var body: some View {
        let skills = SkillsList(requiredSkillsFor: activity).skills
        let tq = TrainingQueue(pilot: pilot ?? .empty)
        tq.addRequiredSkills(for: activity)
        let s = TimeIntervalFormatter.localizedString(from: tq.trainingTime(), precision: .seconds)
        let text = Text("Training time: \(s)").frame(maxWidth: .infinity)
        return ZStack {
            List {
                Section(footer: text) {
                    ForEach(skills, id: \.type.objectID) { skill in
                        NavigationLink(destination: TypeInfo(type: skill.type)) {
                            TypeInfoSkillCell(skillType: skill.type, level: Int(skill.level), pilot: self.pilot)
                        }
                    }
                }
            }.listStyle(GroupedListStyle()).navigationBarTitle(activity.activity?.activityName ?? "")
        }
        .navigationBarItems(trailing: trailingButton)
    }
    
}

struct BlueprintActivityRequiredSkills_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BlueprintActivityRequiredSkills(activity: try! AppDelegate.sharedDelegate.persistentContainer.viewContext
                .from(SDEIndActivity.self)
                .filter((/\SDEIndActivity.requiredSkills).count > 3)
                .first()!)
        }
    }
}

