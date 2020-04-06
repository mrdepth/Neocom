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
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.self) var environment
    
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
        let prefix = Text("SKILLPLAN: ") + (skillPlan.name.map{Text($0.uppercased())} ?? Text("UNNAMED"))
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
                    //                Text("Hello, World!")
                }.onDelete { (indices) in
                    for i in indices {
                        let skill = self.skills[i]
                        skill.managedObjectContext?.delete(skill)
                    }
                }
            }
        }
        .actionSheet(isPresented: $isActionSheetPresented, content: actionSheet)
        .sheet(isPresented: $isSkillPlansPresented) {
            NavigationView {
                SkillPlans() { newSkillPlan in
                    self.isSkillPlansPresented = false
                }
            }.modifier(ServicesViewModifier(environment: self.environment))
        }
    }
}

struct SkillPlanSection_Previews: PreviewProvider {
    static var previews: some View {
        let account = AppDelegate.sharedDelegate.testingAccount
        let esi = account.map{ESI(token: $0.oAuth2Token!)} ?? ESI()

        let type = try! AppDelegate.sharedDelegate.persistentContainer.viewContext
            .from(SDEInvType.self)
            .filter(/\SDEInvType.group?.category?.categoryID == SDECategoryID.skill.rawValue)
            .first()!

        let skillPlan = SkillPlan(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        skillPlan.account = account
        let skills = (0..<4).map { i -> SkillPlanSkill in
            let skill = SkillPlanSkill(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
            skill.typeID = type.typeID
            skill.level = Int16(i)
            skill.skillPlan = skillPlan
            skill.position = Int32(i)
            return skill
        }
        
        let skillPlan2 = SkillPlan(context: AppDelegate.sharedDelegate.persistentContainer.viewContext)
        skillPlan2.account = account
        return NavigationView {
            List {
                SkillPlanSection(skillPlan: skillPlan, pilot: .empty)
                    .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
                    .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
                    .environment(\.account, account)
                    .environment(\.esi, esi)
                SkillPlanSection(skillPlan: skillPlan2, pilot: .empty)
                    .environment(\.managedObjectContext, AppDelegate.sharedDelegate.persistentContainer.viewContext)
                    .environment(\.backgroundManagedObjectContext, AppDelegate.sharedDelegate.persistentContainer.newBackgroundContext())
                    .environment(\.account, account)
                    .environment(\.esi, esi)
            }.listStyle(GroupedListStyle())
        }


    }
}
