//
//  SkillPlanSection.swift
//  Neocom
//
//  Created by Artem Shimanski on 1/29/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import SwiftUI
import Expressible
import CoreData
import EVEAPI

struct SkillPlanSection: View {
    var skillPlan: SkillPlan
    var pilot: Pilot
    @Environment(\.managedObjectContext) private var managedObjectContext
    @Environment(\.self) private var environment
    @EnvironmentObject private var sharedState: SharedState
    
    @FetchRequest(sortDescriptors: [])
    var skills: FetchedResults<SkillPlanSkill>
    
    init(skillPlan: SkillPlan, pilot: Pilot) {
        self.skillPlan = skillPlan
        self.pilot = pilot
        _skills = FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SkillPlanSkill.position, ascending: true)],
                               predicate: (/\SkillPlanSkill.skillPlan == skillPlan).predicate(),
                               animation: nil)
    }
    
    @State private var isActionSheetPresented = false
    @State private var isSkillPlansPresented = false
    
    private func clear() {
        (skillPlan.skills?.allObjects as? [SkillPlanSkill])?.forEach { skill in
            skillPlan.managedObjectContext?.delete(skill)
        }
    }
    
    private func actionSheet() -> ActionSheet {
        var buttons: [ActionSheet.Button] = []

        if (skillPlan.skills?.count ?? 0) > 0 {
            buttons.append(ActionSheet.Button.destructive(Text("Clear"), action: clear))
        }
        buttons.append(ActionSheet.Button.default(Text("Switch"), action: {
            self.isSkillPlansPresented = true
        }))

        buttons.append(ActionSheet.Button.cancel())
        
        return ActionSheet(title: skillPlan.name.map{Text($0)} ?? Text("Unnamed"), message: nil, buttons: buttons)
    }
    
    func header(_ trainingQueue: TrainingQueue) -> some View {
        let trainingTime = trainingQueue.trainingTime()
        let prefix = Text("SKILL PLAN: ") + (skillPlan.name.map{Text($0.uppercased())} ?? Text("UNNAMED"))
        return HStack {
            if trainingTime > 0 {
                prefix + Text(" (\(TimeIntervalFormatter.localizedString(from: trainingTime, precision: .seconds)))")
            }
            else {
                prefix
            }
            Spacer()
            Button(action: {self.isActionSheetPresented = true}) { Image(systemName: "ellipsis") }
        }
    }
    func footer(_ trainingQueue: TrainingQueue) -> some View {
        let trainingTime = trainingQueue.trainingTime()
        return trainingTime == 0 ? Text("SKILL PLAN IS EMPTY").frame(maxWidth: .infinity) : nil
    }
    
    var body: some View {
        let trainingQueue = TrainingQueue(pilot: pilot, skillPlan: skillPlan)

        return Section(header: header(trainingQueue)) {
            if trainingQueue.trainingTime() == 0 {
                NavigationLink(destination: Skills(editMode: true)) {
                    Text("Add Skills")
                }
            }
            else {
                ForEach(skills, id: \.objectID) { skill in
                    Group {
                        if (self.pilot.trainedSkills[Int(skill.typeID)]?.trainedSkillLevel ?? 0) < Int(skill.level) {
                            (try? self.managedObjectContext.from(SDEInvType.self).filter(/\SDEInvType.typeID == Int32(skill.typeID)).first()).map { type in
                                SkillCell(type: type, pilot: self.pilot, skillPlanSkill: skill)
                            }
                        }
                    }
                }
                .onDelete { (indices) in
                    for i in indices {
                        let skill = self.skills[i]
                        skill.managedObjectContext?.delete(skill)
                    }
                }
                .onMove { (from, to) in
                    var skills = Array(self.skills)
                    skills.move(fromOffsets: from, toOffset: to)
                    skills.enumerated().forEach{$0.element.position = Int32($0.offset)}
                }
            }
        }
        .actionSheet(isPresented: $isActionSheetPresented, content: actionSheet)
        .sheet(isPresented: $isSkillPlansPresented) {
            NavigationView {
                SkillPlans() { newSkillPlan in
                    self.isSkillPlansPresented = false
                }
            }
            .modifier(ServicesViewModifier(environment: self.environment, sharedState: self.sharedState))
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

#if DEBUG
struct SkillPlanSection_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount

        let type = try! Storage.sharedStorage.persistentContainer.viewContext
            .from(SDEInvType.self)
            .filter(/\SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue)
            .first()!

        let skillPlan = SkillPlan(context: Storage.sharedStorage.persistentContainer.viewContext)
        skillPlan.account = account
        (0..<4).forEach { i in
            let skill = SkillPlanSkill(context: Storage.sharedStorage.persistentContainer.viewContext)
            skill.typeID = type.typeID
            skill.level = Int16(i)
            skill.skillPlan = skillPlan
            skill.position = Int32(i)
        }
        
        let skillPlan2 = SkillPlan(context: Storage.sharedStorage.persistentContainer.viewContext)
        skillPlan2.account = account
        return NavigationView {
            List {
                SkillPlanSection(skillPlan: skillPlan, pilot: .empty)
                SkillPlanSection(skillPlan: skillPlan2, pilot: .empty)
            }.listStyle(GroupedListStyle())
        }
        .environment(\.managedObjectContext, Storage.sharedStorage.persistentContainer.viewContext)
        .environment(\.backgroundManagedObjectContext, Storage.sharedStorage.persistentContainer.newBackgroundContext())
        .environmentObject(SharedState.testState())


    }
}
#endif
