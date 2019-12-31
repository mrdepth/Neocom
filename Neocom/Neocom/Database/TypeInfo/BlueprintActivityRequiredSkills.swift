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
    @State private var sheetIsPresented = false
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
    
//    private func requiredSkills(for activity: SDEIndActivity, pilot: Pilot?) {
//        (activity.requiredSkills?.allObjects as? [SDEIndRequiredSkill])?.filter {$0.skillType?.typeName != nil}.sorted {$0.skillType!.typeName! < $1.skillType!.typeName!}
////            .compactMap { requiredSkill -> Tree.Item.InvTypeRequiredSkillRow? in
////            guard let type = requiredSkill.skillType else {return nil}
////            guard let row = Tree.Item.InvTypeRequiredSkillRow(requiredSkill, character: character) else {return nil}
////            row.children = requiredSkills(for: type, character: character, context: context)
////            return row
//        }
//    }

    private var trailingButton: some View {
//        return (!trainingQueue.queue.isEmpty ? account?.activeSkillPlan : nil).map { skillPlan in
            Button(action: {
                self.sheetIsPresented.toggle()
            }) {
                Image(systemName: "ellipsis")
            }
//        }
    }
    
    private var actionSheet: ActionSheet {
        ActionSheet(title: Text(TimeIntervalFormatter.localizedString(from: trainingQueue.trainingTime(), precision: .seconds)), message: nil, buttons: [
            .default(Text("Add to Skill Plan")) {
                self.account?.activeSkillPlan?.add(self.trainingQueue)
                withAnimation {
                    self.isFinished.toggle()
                }
            },
            .cancel()])
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
            }.listStyle(GroupedListStyle()).navigationBarTitle("Required Skills")
            if isFinished {
                FinishedView(isPresented: $isFinished)
            }
        }
        .navigationBarItems(trailing: trailingButton)
        .actionSheet(isPresented: $sheetIsPresented) {self.actionSheet}
            
    }
    
}

struct BlueprintActivityRequiredSkills_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BlueprintActivityRequiredSkills(activity: try! AppDelegate.sharedDelegate.persistentContainer.viewContext
                .from(SDEIndActivity.self)
                .filter((\SDEIndActivity.requiredSkills).count > 3)
                .first()!)
        }
    }
}

